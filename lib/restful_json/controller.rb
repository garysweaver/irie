require 'restful_json/config'
require 'active_model_serializers'
require 'strong_parameters'
require 'convenient-actionpack'

module RestfulJson
  module Controller
    extend ActiveSupport::Concern

    included do
      NEW = 'new'
      EDIT = 'edit'
      send :include, ::ActiveModel::ForbiddenAttributesProtection
      send :include, ::ActionController::Serialization
      send :include, ::ActionController::StrongParameters
      send :include, ::TwinTurbo::Controller
      send :include, ::Convenient::Controller
    end

    module ClassMethods
      def acts_as_restful_json(options = {})
        include ActsAsRestfulJson
      end
    end
    
    module ActsAsRestfulJson
      extend ActiveSupport::Concern

      included do
        #
        #before_filter :before_request
        #after_filter :after_request

        # create class attributes for each controller option and set the value to the value in the app configuration
        class_attribute :model_class, instance_writer: true
        class_attribute :model_singular_name, instance_writer: true
        class_attribute :model_plural_name, instance_writer: true
        class_attribute :model_created_message, instance_writer: true
        class_attribute :model_updated_message, instance_writer: true
        class_attribute :param_to_attr_and_arel_predicate, instance_writer: true
        class_attribute :supported_functions, instance_writer: true

        # TODO: keep? You can blame these on an attempt at premature optimization. Without them aren't there lots of small strings in requests that have to be GC'd, or should we ditch setting instance vars dynamically?
        class_attribute :model_at_plural_name_sym, instance_writer: true
        class_attribute :model_plural_name_sym, instance_writer: true
        class_attribute :model_at_plural_name, instance_writer: true
        class_attribute :model_plural_name_url, instance_writer: true
        class_attribute :model_at_singular_name_sym, instance_writer: true
        class_attribute :model_singular_name_sym, instance_writer: true
        class_attribute :model_at_singular_name, instance_writer: true

        # use values from config
        RestfulJson::CONTROLLER_OPTIONS.each do |key|
          class_attribute key, instance_writer: true
          self.send("#{key}=".to_sym, RestfulJson.send(key))
        end
        
        # if not set, use controller classname
        self.model_class ||= self.name.chomp('Controller').split('::').last.singularize.constantize
        self.model_singular_name ||= self.model_class.name.underscore
        self.model_plural_name ||= self.model_singular_name.pluralize

        # set strings that shouldn't have to be set more than at initialization time. this should be done in the setter overrides it isn't working yet.
        self.model_created_message = "#{model_class} was successfully created.".freeze
        self.model_updated_message = "#{model_class} was successfully updated.".freeze
        self.model_at_plural_name = "@#{model_plural_name}".freeze
        self.model_at_plural_name_sym = "@#{model_plural_name}".to_sym
        self.model_at_singular_name = "@#{model_singular_name}".freeze
        self.model_at_singular_name_sym = "@#{model_plural_name}".to_sym
        self.model_plural_name_sym = model_plural_name.to_sym
        self.model_plural_name_url = "#{model_plural_name}_url".freeze
        self.model_singular_name_sym = model_singular_name.to_sym
        
        self.param_to_attr_and_arel_predicate ||= {}
        self.supported_functions ||= []

        # this can be overriden, but it is restful_json...
        respond_to :json
      end

      module ClassMethods

        # Whitelist attributes that are queryable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
        # can_filter_by :attr_name_1, :attr_name_2 # implied using: [eq] if RestfulJson.can_filter_by_default_using = [:eq] 
        # can_filter_by :attr_name_1, :attr_name_2, using: [:eq, :not_eq]
        def can_filter_by(*args)
          options = args.extract_options!
          predicates = Array.wrap(options[:using] || self.can_filter_by_default_using)
          predicates.each do |predicate|
            predicate_sym = predicate.to_sym
            args.each do |attr|
              attr_sym = attr.to_sym
              self.param_to_attr_and_arel_predicate[attr_sym] = [attr_sym, :eq] if predicate_sym == :eq
              self.param_to_attr_and_arel_predicate["#{attr}#{self.predicate_prefix}#{predicate}".to_sym] = [attr_sym, predicate_sym]
            end
          end
        end

        # Can specify additional functions in the index, e.g.
        # supports_functions :skip, :uniq, :take, :count
        def supports_functions(functions)
          self.supported_functions += Array.wrap(functions)
        end

      end

      def initialize
        super
        raise "#{self.class.name} failed to initialize. self.model_class was nil in #{self} which shouldn't happen!" if self.model_class.nil?
        # note: we are overriding class attribute setters locally to attempt to set strings to allow us to set @foos and @foo without additional string creation per request
        raise "#{self.class.name} assumes that #{self.model_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless self.model_class.ancestors.include?(ActiveRecord::Base)
        puts "'#{self}' self.model_class=#{self.model_class}, self.model_singular_name=#{self.model_singular_name}, self.model_plural_name=#{self.model_plural_name}" if self.debug?
      end

      def convert_request_param_value_for_filtering(attr_sym, value)
        value && ['NULL','null','nil'].include?(value) ? nil : value
      end

      def index
        t = self.model_class.arel_table
        value = self.model_class.scoped
        self.param_to_attr_and_arel_predicate.keys.each do |param_name|
          param = params[param_name]
          if param.present? && param_to_attr_and_arel_predicate[param_name]
            attr_sym = param_to_attr_and_arel_predicate[param_name][0]
            predicate_sym = param_to_attr_and_arel_predicate[param_name][1]
            if predicate_sym == :eq
              puts ".where(#{attr_sym.inspect} => convert_request_param_value_for_filtering(#{attr_sym.inspect}, #{param.inspect}))" if self.debug?
              value = value.where(attr_sym => convert_request_param_value_for_filtering(attr_sym, param))
            else
              one_or_more_param = param.split(self.filter_split).collect{|v|convert_request_param_value_for_filtering(attr_sym, v)}
              puts ".where(t[#{attr_sym.inspect}].try(#{predicate_sym.inspect}, #{one_or_more_param.inspect}))" if self.debug?
              value = value.where(t[attr_sym].try(predicate_sym, one_or_more_param))
            end
          end
        end
        
        if params[:skip] && self.supported_functions.include?(:skip)
          value = value.take(params[:skip])
        end
        
        if params[:take] && self.supported_functions.include?(:take)
          value = value.take(params[:take])
        end
        
        if params[:uniq] && self.supported_functions.include?(:uniq)
          value = value.uniq
        end

        if params[:count] && self.supported_functions.include?(:count)
          value = value.count
        end
        
        @value = value

        instance_variable_set(self.model_at_plural_name_sym, @value)

        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @value }
        end
      end

      def show
        @value = self.model_class.find(params[:id])
        instance_variable_set(self.model_at_singular_name_sym, @value)
        respond_with @value
      end

      def new
        @value = self.model_class.new
        respond_with @value
      end

      def edit
        @value = self.model_class.find(params[:id])
        instance_variable_set(self.model_at_singular_name_sym, @value)
      end

      def create
        authorize! :create, self.model_class
        @value = self.model_class.new(permitted_params)
        @value.save
        instance_variable_set(self.model_at_singular_name_sym, @value)
        respond_with @value
      end

      def update
        authorize! :update, self.model_class
        @value = self.model_class.find(params[:id])
        self.model_class.update_attributes(permitted_params)
        instance_variable_set(self.model_at_singular_name_sym, @value)
        respond_with @value
      end

      def destroy
        @value = self.model_class.find(params[:id])
        @value.destroy
        instance_variable_set(self.model_at_singular_name_sym, @value)
        respond_with @value
      end
    end
  end
end
