module Actionizer
  module Actions
    module Update
      extend ::ActiveSupport::Concern

      ::Actionizer.available_actions[:update] = '::' + Update.name

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Finders

        Array.wrap(self.autoincludes[:update]).each do |obj|
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

      # The controller's update (put) method to update a resource.
      def update
        logger.debug("Actionizer::Actions::Update.update") if Actionizer.debug?
        return catch(:action_break) do
          render_update perform_update(params_for_update)
        end || @action_result
      end

      def params_for_update
        logger.debug("Actionizer::Actions::Update.params_for_update") if Actionizer.debug?
        __send__(instance_name_params_sym)
      end

      def perform_update(the_params)
        logger.debug("Actionizer::Actions::Update.perform_update(#{the_params.inspect})") if Actionizer.debug?
        record = find_model_instance!(the_params)
        record.update_attributes(the_params)
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_update(record)
        logger.debug("Actionizer::Actions::Update.render_update(#{record.inspect})") if Actionizer.debug?
        include_instance_in_render = self.update_should_return_entity || (record.respond_to?(:errors) && record.errors.size > 0)
        perform_render(include_instance_in_render ? record : nil)
      end
    end
  end
end
