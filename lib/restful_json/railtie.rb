require 'restful_json'

module RestfulJson
  class Railtie < Rails::Railtie
    initializer "restful_json.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        puts "Extending #{self} with RestfulJson::Controller"
        # on every controller, define methods
        extend RestfulJson::Controller
        # InstanceMethods only included if acts_as_restful_json called
        #puts "self=#{self} new methods: #{self.methods.sort.join(', ')}"
      end
    end

    initializer "restful_json.active_record" do
      ActiveSupport.on_load(:active_record) do
        puts "Extending #{self} with RestfulJson::Model"
        # on every model, define methods
        extend RestfulJson::Model
        include RestfulJson::Model::InstanceMethods
        #puts "self=#{self} new methods: #{self.methods.sort.join(', ')}"
      end
    end
  end
end
