require 'restful_json'

module RestfulJson
  class Railtie < ::Rails::Railtie
    initializer "restful_json.action_controller" do
      # provide deprecated acts_as_restful_json method on controller
      ActiveSupport.on_load(:action_controller) do
        include ::RestfulJson::BaseController
      end
    end

    #TODO: split permitters out into their own gem, and then can always add to autoload path if gem loaded
    initializer "restful_json.autoload_paths", after: :load_config_initializers do
      if RestfulJson.use_permitters
        ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/app/permitters" unless ActiveSupport::Dependencies.autoload_paths.include?("#{Rails.root}/app/permitters")
      end
    end
  end
end
