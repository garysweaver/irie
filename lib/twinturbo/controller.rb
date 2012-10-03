module TwinTurbo
  module Controller
    # Instance Methods:

    # the following methods are from Adam Hawkins's post:
    # http://www.broadcastingadam.com/2012/07/parameter_authorization_in_rails_apis/
    
    def permitted_params
      @permitted_params ||= permitter.permitted_params
    end

    def permitter
      return unless permitter_class

      @permitter ||= permitter_class.new params, current_user, current_ability
    end

    def permitter_class
      begin
        puts "Attempting to match #{self.class.to_s} which should be a *Controller"
        "#{self.class.to_s.match(/(.+)Controller/)[1].singularize}Permitter".constantize
      rescue NameError
        nil
      end
    end
  end
end
