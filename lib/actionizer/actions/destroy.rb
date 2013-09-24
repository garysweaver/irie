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
              raise "Could not resolve extension module. Check Actionizer/self.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
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

      # The controller's destroy (delete) method to destroy a resource.
      # RESTful delete is idempotent, i.e. does not fail if the record does not exist.
      def destroy
        return catch(:action_break) do
          render_destroy perform_destroy(params_for_destroy)
        end || @action_result
      end

      def params_for_destroy
        params
      end

      def perform_destroy(the_params)
        record = find_model_instance(the_params)
        @destroy_result = record.destroy if record
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def render_destroy(record)
        respond_with record, (render_destroy_options(record) || {}).merge(self.action_to_valid_render_options[:destroy] || {})
      end

      def render_destroy_options(record)
        {}
      end
    end
  end
end
