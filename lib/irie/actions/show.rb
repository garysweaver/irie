module Irie
  module Actions
    module Show
      extend ::ActiveSupport::Concern

      ::Irie.available_actions[:show] = '::' + Show.name

      included do
        include ::Irie::Actions::Base
        include ::Irie::Actions::Common::Finders

        Array.wrap(self.autoincludes[:show]).each do |obj|
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

      # The controller's show (get) method to return a resource.
      def show(options={}, &block)
        logger.debug("Irie::Actions::Show.show") if Irie.debug?
        return catch(:action_break) do
          render_show perform_show(params_for_show)
        end || @action_result
      end

      def perform_show(the_params)
        logger.debug("Irie::Actions::Show.perform_show(#{the_params.inspect})") if Irie.debug?
        record = find_model_instance!(the_params)
        instance_variable_set(instance_variable_name_sym, record)
      end

      def params_for_show
        logger.debug("Irie::Actions::Show.params_for_show") if Irie.debug?
        params
      end

      def render_show(record)
        logger.debug("Irie::Actions::Show.render_show(#{record.inspect})") if Irie.debug?
        perform_render(record)
      end
    end
  end
end
