module Irie
  module Actions
    module New
      extend ::ActiveSupport::Concern

      ::Irie.available_actions[:new] = '::' + New.name

      included do
        include ::Irie::Actions::Base
        include ::Irie::Actions::Common::Creator

        Array.wrap(self.autoincludes[:new]).each do |obj|
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

      # The controller's new method (e.g. used for new record in html format).
      def new(options={}, &block)
        logger.debug("Irie::Actions::New.new") if Irie.debug?
        return catch(:action_break) do
          render_new perform_new(params_for_new)
        end || @action_result
      end

      # Default is to return nil since these usually set in column defaults or model initialize,
      # but can be overriden if you need to set in the controller.
      def params_for_new
        logger.debug("Irie::Actions::New.params_for_new") if Irie.debug?
        nil
      end

      def perform_new(the_params)
        logger.debug("Irie::Actions::New.perform_new(#{the_params.inspect})") if Irie.debug?
        instance_variable_set(instance_variable_name_sym, new_model_instance(the_params))
      end

      def render_new(record)
        logger.debug("Irie::Actions::New.render_new(#{record.inspect})") if Irie.debug?
        perform_render(record)
      end
    end
  end
end
