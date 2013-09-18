module Actionizer
  module Actions
    module Destroy
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Finders
      end

      # The controller's destroy (delete) method to destroy a resource.
      # RESTful delete is idempotent, i.e. does not fail if the record does not exist.
      def destroy
        return catch(:action_break) do
          render_destroy perform_destroy(params_for_destroy)
        end || @action_result
      end

      def params_for_destroy
        @aparams = params
      end

      def perform_destroy(aparams)
        record = find_model_instance(aparams)
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
