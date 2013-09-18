module Actionizer
  module Actions
    module New
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::Actions::Base
      end

      # The controller's new method (e.g. used for new record in html format).
      def new
        return catch(:action_break) do
          render_new perform_new(params_for_new)
        end || @action_result
      end

      def params_for_new
        @aparams = params
      end

      def perform_new(aparams)
        instance_variable_set(@model_at_singular_name_sym, @model_class.new)
      end

      def render_new(record)
        respond_with record, (render_new_valid_options(record) || {}).merge(self.action_to_valid_render_options[:new] || {})
      end

      def render_new_valid_options(record)
        {}
      end
    end
  end
end
