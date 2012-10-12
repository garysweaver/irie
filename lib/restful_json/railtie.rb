require 'restful_json'

module RestfulJson
  class Railtie < Rails::Railtie
    initializer "restful_json.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        puts "Extending #{self} with RestfulJson::Controller" if RestfulJson.debug?
        include RestfulJson::Controller
      end
    end

    initializer "restful_json.active_record" do
      ActiveSupport.on_load(:active_record) do
        puts "Extending #{self} with RestfulJson::Model" if RestfulJson.debug?
        include RestfulJson::Model
      end
    end
  end
end
