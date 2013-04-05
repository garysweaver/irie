require 'restful_json'

module RestfulJson
  class Railtie < ::Rails::Railtie
    initializer "restful_json.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        include ::RestfulJson::BaseController
      end
    end
  end
end
