module Actionizer
  module Actions
    module Show
      extend ::ActiveSupport::Concern
      Actionizer.available_actions[:show] = '::' + Show.name

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Finders
      end

      # The controller's show (get) method to return a resource.
      def show
        return catch(:action_break) do
          render_show perform_show(params_for_show)
        end || @action_result
      end

      def perform_show(the_params)
        record = find_model_instance!(the_params)
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def params_for_show
        params
      end

      def render_show(record)
        respond_with record, (render_show_options(record) || {}).merge(self.action_to_valid_render_options[:show] || {})
      end

      def render_show_options(record)
        {}
      end
    end
  end
end
