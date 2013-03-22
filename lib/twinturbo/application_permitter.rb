# from Adam Hawkins's gist:
# https://gist.github.com/3150306
# http://www.broadcastingadam.com/2012/07/parameter_authorization_in_rails_apis/
class ApplicationPermitter
  class PermittedAttribute < Struct.new(:name, :options) ; end

  delegate :authorize!, :to => :ability
  class_attribute :permitted_attributes
  self.permitted_attributes = []

  class << self
    def permit(*args)
      options = args.extract_options!

      args.each do |name|
        self.permitted_attributes += [PermittedAttribute.new(name, options)]
      end
    end

    def scope(name)
      with_options :scope => name do |nested|
        yield nested
      end
    end
  end

  def initialize(params, user, ability = nil)
    @params, @user, @ability = params, user, ability
  end

  def permitted_params
    authorize_params!
    filtered_params
  end

  def resource_name
    self.class.to_s.match(/(.+)Permitter/)[1].underscore.to_sym
  end


private

  def authorize_params!
    needing_authorization = permitted_attributes.select { |a| a.options[:authorize] }

    needing_authorization.each do |attribute|
      if attribute.options[:scope]
        values = Array.wrap(filtered_params[attribute.options[:scope]]).collect do |hash|
          hash[attribute.name]
        end.compact
      else
        values = Array.wrap filtered_params[attribute.name]
      end

      klass = (attribute.options[:as].try(:to_s) || attribute.name.to_s.split(/(.+)_ids?/)[1]).classify.constantize

      values.each do |record_id|
        record = klass.find record_id
        permission = attribute.options[:authorize].to_sym || :read
        authorize! permission, record
      end
    end
  end

  def filtered_params
    scopes = {}
    unscoped_attributes = []

    permitted_attributes.each do |attribute|
      if attribute.options[:scope]
        key = attribute.options[:scope]
        scopes[key] ||= []
        scopes[key] << attribute.name
      else
        unscoped_attributes << attribute.name
      end
    end

    @filtered_params ||= params.require(resource_name).permit(*unscoped_attributes, scopes)
  end

  def params
    @params
  end

  def user
    @user
  end

  def ability
    @ability ||= Ability.new user
  end
end
