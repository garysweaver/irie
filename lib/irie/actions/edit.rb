module Irie
  module Actions
    module Edit
      extend ::ActiveSupport::Concern
      
      ::Irie.available_actions[:edit] = '::' + Edit.name

      included do
        include ::Irie::Actions::Base
        include ::Irie::Actions::Common::Finders
        
        Array.wrap(self.autoincludes[:edit]).each do |obj|
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

      # The controller's edit method (e.g. used for edit record in html format).
      def edit(options={}, &block)
        logger.debug("Irie::Actions::Edit.edit") if Irie.debug?
        return catch(:action_break) do
          render_edit perform_edit(params_for_edit)
        end || @action_result
      end

      def params_for_edit
        logger.debug("Irie::Actions::Edit.params_for_edit") if Irie.debug?
        params
      end

      def perform_edit(the_params)
        logger.debug("Irie::Actions::Edit.perform_edit(#{the_params.inspect})") if Irie.debug?
        record = find_model_instance!(the_params)
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_edit(record)
        logger.debug("Irie::Actions::Edit.render_edit(#{record.inspect})") if Irie.debug?
        perform_render(record)
      end
    end
  end
end
