module Actionize
  module Actions
    module Update
      extend ::ActiveSupport::Concern

      include ::Actionize::Actions::Base,
              ::Actionize::Actions::Common::Finders

      # The controller's update (put) method to update a resource.
      def update
        render_update perform_update(params_for_update)
      end

      def params_for_update
        @aparams = __send__(@model_singular_name_params_sym)
      end

      def perform_update(aparams)
        record = find_model_instance!(aparams)
        @update_result = record.update_attributes(@aparams)
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def render_update(record)
        record.respond_to?(:errors) && record.errors.size > 0 ? render_update_invalid(record) : render_update_valid(record)
      end

      def render_update_invalid(record)
        render_update_valid(record)
      end

      def render_update_valid(record)
        respond_with record, (render_update_valid_options(record) || {}).merge(self.action_to_valid_render_options[:update] || {})
      end

      def render_update_valid_options(record)
        {}
      end
    end
  end
end
