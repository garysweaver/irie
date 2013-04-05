module TwinTurbo
  module Controller

    # modded from Adam Hawkins's original post:
    # http://www.broadcastingadam.com/2012/07/parameter_authorization_in_rails_apis/
    # with modification to only try to call permitted params if is a permitter
    
    def permitted_params
      #TODO: provide way of producing error if params invalid (not as simple as not rescuing- need to rework permitters)
      @permitted_params ||= safe_permitted_params
    end

    def permitter
      return unless permitter_class

      @permitter ||= permitter_class.new params, current_user, current_ability
    end

    def permitter_class
      # Try "The::Controller::Namespace::(singular name)Controller".contantize.
      # If controller in a module, will fall back on "(singular name)Controller".contantize.
      permitter_class_arr = ["#{self.class.to_s.match(/(.+)Controller/)[1].singularize}Permitter"]
      if self.class.to_s['::']
        permitter_class_arr << "#{self.class.to_s.match(/(.*?::)?(?<controller_name>.+)Controller/)[:controller_name].singularize}Permitter"
      end
      permitter_class_arr.each do |class_name|
        begin
          return class_name.constantize
        rescue NameError
          puts "#{class_name} not found"
        end
      end
      nil
    end

    def safe_permitted_params
      begin
        permitter.send(:permitted_params)
      rescue
      end
    end
  end
end
