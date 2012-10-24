module TwinTurbo
  module Controller
    # Instance Methods:

    # the following methods are from Adam Hawkins's post:
    # http://www.broadcastingadam.com/2012/07/parameter_authorization_in_rails_apis/
    # with modification to only try to call permitted params if is a permitter
    
    def permitted_params
      # if you send invalid content, it will return an HTTP 20x for a put and a 422 for a post, instead of a 500 for both.
      @permitted_params ||= safe_permitted_params
    end

    def permitter
      return unless permitter_class

      @permitter ||= permitter_class.new params, current_user, current_ability
    end

    def permitter_class
      begin
        "#{self.class.to_s.match(/(.*?::)?(?<controller_name>.+)Controller/)[:controller_name].singularize}Permitter".constantize
      rescue NameError
        nil
      end
    end

    def safe_permitted_params
      begin
        permitter.send(:permitted_params)
      rescue
      end
    end
  end
end
