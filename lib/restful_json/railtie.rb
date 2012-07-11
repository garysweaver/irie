require 'restful_json'

module RestfulJson
  class Railtie < Rails::Railtie
    initializer "restful_json.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        puts "Including RestfulJson on #{self}."
        # on every controller. define self.restful_json_controller, which can be called by controller to define a lot of methods.
        extend RestfulJson::Controller
        puts "self=#{self} new methods: #{self.methods.sort.join(', ')}"
      end
    end

    initializer "restful_json.active_record" do
      ActiveSupport.on_load(:active_record) do
        puts "Including RestfulJson Model methods on #{self}."        
        # on every model, define self.json_options and related methods to set json formatting options.
        extend RestfulJson::Model        
        puts "self=#{self} new methods: #{self.methods.sort.join(', ')}"
      end
    end
  end
end
