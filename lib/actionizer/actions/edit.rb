module Actionizer
  module Actions
    module Edit
      extend ::ActiveSupport::Concern
      
      ::Actionizer.available_actions[:edit] = '::' + Edit.name

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Finders
        
        Array.wrap(self.autoincludes[:edit]).each do |obj|
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

      # The controller's edit method (e.g. used for edit record in html format).
      def edit
        logger.debug("Actionizer::Actions::Edit.edit") if Actionizer.debug?
        return catch(:action_break) do
          render_edit perform_edit(params_for_edit)
        end || @action_result
      end

      def params_for_edit
        logger.debug("Actionizer::Actions::Edit.params_for_edit") if Actionizer.debug?
        params
      end

      def perform_edit(the_params)
        logger.debug("Actionizer::Actions::Edit.perform_edit(#{the_params.inspect})") if Actionizer.debug?
        record = find_model_instance!(the_params)
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_edit(record)
        logger.debug("Actionizer::Actions::Edit.render_edit(#{record.inspect})") if Actionizer.debug?
        perform_render(record)
      end
    end
  end
end
