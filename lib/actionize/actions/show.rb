module Actionize
  module Actions
    module Show
      extend ::ActiveSupport::Concern

      include ::Actionize::Actions::Base,
              ::Actionize::Actions::Common::Finders

      # The controller's show (get) method to return a resource.
      def show
        render_show perform_show(params_for_show)
      end

      def perform_show(aparams)
        record = find_model_instance!(aparams)
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def params_for_show
        @aparams = params
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
