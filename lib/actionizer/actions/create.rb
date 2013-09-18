module Actionizer
  module Actions
    module Create
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::Actions::Base
      end        

      # The controller's create (post) method to create a resource.
      def create
        return catch(:action_break) do
          render_create perform_create(params_for_create)
        end || @action_result
      end

      def params_for_create
        @aparams = __send__(@model_singular_name_params_sym)
      end

      def perform_create(aparams)
        record = @model_class.new(@aparams)
        @save_result = record.save
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def render_create(record)
        record.respond_to?(:errors) && record.errors.size > 0 ? render_create_invalid(record) : render_create_valid(record)
      end

      def render_create_invalid(record)
        render_create_valid(record)
      end

      def render_create_valid(record)
        respond_with record, (render_create_valid_options(record) || {}).merge(self.action_to_valid_render_options[:create] || {})
      end

      def render_create_valid_options(record)
        {}
      end
    end
  end
end
