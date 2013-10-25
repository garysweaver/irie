module Irie
  module Actions
    module Create
      extend ::ActiveSupport::Concern

      ::Irie.available_actions[:create] = '::' + Create.name

      included do
        include ::Irie::Actions::Base
        include ::Irie::Actions::Common::Creator
        
        Array.wrap(self.autoincludes[:create]).each do |obj|
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

      # The controller's create (post) method to create a resource.
      def create(options={}, &block)
        logger.debug("Irie::Actions::Create.create") if Irie.debug?
        return catch(:action_break) do
          render_create perform_create(params_for_create)
        end || @action_result
      end

      def params_for_create
        logger.debug("Irie::Actions::Create.params_for_create") if Irie.debug?
        __send__(instance_name_params_sym)
      end

      def perform_create(the_params)
        logger.debug("Irie::Actions::Create.perform_create(#{the_params.inspect})") if Irie.debug?
        record = new_model_instance(the_params)
        record.save
        instance_variable_set(instance_variable_name_sym, record)
      end

      def render_create(record)
        logger.debug("Irie::Actions::Create.render_create(#{record.inspect})") if Irie.debug?
        perform_render(record)
      end
    end
  end
end
