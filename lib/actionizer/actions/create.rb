module Actionizer
  module Actions
    module Create
      extend ::ActiveSupport::Concern

      ::Actionizer.available_actions[:create] = '::' + Create.name

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Creator
        
        Array.wrap(self.autoincludes[:create]).each do |obj|
          case obj
          when Symbol
            begin
              include self.available_extensions[obj.to_sym].constantize
            rescue NameError => e
              raise "Could not resolve extension module '#{self.available_extensions[obj.to_sym]}' for key for #{obj.to_sym.inspect}. Check Actionizer/self.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          when String
            begin
              include obj.constantize
            rescue NameError => e
              raise "Could not resolve extension module: #{obj}. Error: \n#{e.message}\n\n#{e.backtrace.join("\n")}"
            end
          else
            include obj
          end
        end
      end

      # The controller's create (post) method to create a resource.
      def create
        logger.debug("Actionizer::Actions::Create.create") if Actionizer.debug?
        return catch(:action_break) do
          render_create perform_create(params_for_create)
        end || @action_result
      end

      def params_for_create
        logger.debug("Actionizer::Actions::Create.params_for_create") if Actionizer.debug?
        __send__(instance_name_params_sym)
      end

      def perform_create(the_params)
        logger.debug("Actionizer::Actions::Create.perform_create(#{the_params.inspect})") if Actionizer.debug?
        record = new_model_instance(the_params)
        record.save
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_create(record)
        logger.debug("Actionizer::Actions::Create.render_create(#{record.inspect})") if Actionizer.debug?
        perform_render(record)
      end
    end
  end
end
