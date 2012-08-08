require 'restful_json'

module RestfulJson
  class Railtie < Rails::Railtie
    initializer "restful_json.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        puts "Extending #{self} with RestfulJson::Controller"
        # ActionController::Base gets a method that allows controllers to include the new behavior
        extend RestfulJson::Controller
      end
    end

    initializer "restful_json.active_record" do
      ActiveSupport.on_load(:active_record) do
        puts "Extending #{self} with RestfulJson::Model"
        # ActiveRecord::Base gets new behavior
        include RestfulJson::Model # ActiveSupport::Concern
      end
    end
  end
end
