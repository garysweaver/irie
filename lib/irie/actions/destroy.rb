module Irie
  module Actions
    module Destroy
      extend ::ActiveSupport::Concern

      ::Irie.available_actions[:destroy] = '::' + Destroy.name

      included do
        include ::Irie::Actions::Base
        include ::Irie::Actions::Common::Finders

        Array.wrap(self.autoincludes[:destroy]).each do |obj|
          case obj
          when Symbol
            begin
              include Irie.available_extensions[obj.to_sym].constantize
            rescue NameError => e
              raise ::Irie::ConfigurationError.new "Could not resolve extension module '#{Irie.available_extensions[obj.to_sym]}' for key for #{obj.to_sym.inspect}. Check Irie/Irie.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          when String
            begin
              include obj.constantize
            rescue NameError => e
              raise ::Irie::ConfigurationError.new "Could not resolve extension module: #{obj}. Error: \n#{e.message}\n\n#{e.backtrace.join("\n")}"
            end
          else
            include obj
          end
        end
      end

      # The controller's destroy (delete) method to destroy a resource.
      # RESTful delete is idempotent, i.e. does not fail if the record does not exist.
      def destroy(options={}, &block)
        logger.debug("Irie::Actions::Destroy.destroy") if Irie.debug?
        return catch(:action_break) do
          render_destroy perform_destroy(params_for_destroy)
        end || @action_result
      end

      def params_for_destroy
        logger.debug("Irie::Actions::Destroy.params_for_destroy") if Irie.debug?
        params
      end

      def perform_destroy(the_params)
        logger.debug("Irie::Actions::Destroy.perform_destroy(#{the_params.inspect})") if Irie.debug?
        record = find_model_instance(the_params)
        @destroy_result = record.destroy if record
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_destroy(record)
        logger.debug("Irie::Actions::Destroy.render_destroy(#{record.inspect})") if Irie.debug?
        perform_render(record)
      end
    end
  end
end
