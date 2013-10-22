module Actionizer
  module Actions
    module Destroy
      extend ::ActiveSupport::Concern

      ::Actionizer.available_actions[:destroy] = '::' + Destroy.name

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Finders

        Array.wrap(self.autoincludes[:destroy]).each do |obj|
          case obj
          when Symbol
            begin
              include self.available_extensions[obj.to_sym].constantize
            rescue NameError => e
              raise ::Actionizer::ConfigurationError.new "Could not resolve extension module '#{self.available_extensions[obj.to_sym]}' for key for #{obj.to_sym.inspect}. Check Actionizer/self.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          when String
            begin
              include obj.constantize
            rescue NameError => e
              raise ::Actionizer::ConfigurationError.new "Could not resolve extension module: #{obj}. Error: \n#{e.message}\n\n#{e.backtrace.join("\n")}"
            end
          else
            include obj
          end
        end
      end

      # The controller's destroy (delete) method to destroy a resource.
      # RESTful delete is idempotent, i.e. does not fail if the record does not exist.
      def destroy
        logger.debug("Actionizer::Actions::Destroy.destroy") if Actionizer.debug?
        return catch(:action_break) do
          render_destroy perform_destroy(params_for_destroy)
        end || @action_result
      end

      def params_for_destroy
        logger.debug("Actionizer::Actions::Destroy.params_for_destroy") if Actionizer.debug?
        params
      end

      def perform_destroy(the_params)
        logger.debug("Actionizer::Actions::Destroy.perform_destroy(#{the_params.inspect})") if Actionizer.debug?
        record = find_model_instance(the_params)
        @destroy_result = record.destroy if record
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_destroy(record)
        logger.debug("Actionizer::Actions::Destroy.render_destroy(#{record.inspect})") if Actionizer.debug?
        perform_render(record)
      end
    end
  end
end
