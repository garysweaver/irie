module Actionize
  module Actions
    module Edit
      extend ::ActiveSupport::Concern

      include ::Actionize::Actions::Base,
              ::Actionize::Actions::Common::Finders

      # The controller's edit method (e.g. used for edit record in html format).
      def edit
        render_edit perform_edit(params_for_edit)
      end

      def params_for_edit
        @aparams = params
      end

      def perform_edit(aparams)
        record = find_model_instance!(aparams)
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def render_edit(record)
        respond_with record, (render_edit_options(record) || {}).merge(self.action_to_valid_render_options[:edit] || {})
      end

      def render_edit_options(record)
        {}
      end
    end
  end
end
