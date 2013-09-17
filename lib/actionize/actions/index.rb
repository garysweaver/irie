module Actionize
  module Actions
    module Index
      extend ::ActiveSupport::Concern

      include ::Actionize::Actions::Base
      include ::Actionize::RegistersFunctions
      include ::Actionize::ExecutesFunctions

      included do
        function_groups :index_filters,
                        :after_index_filters
      end

      # The controller's index (list) method to list resources.
      def index
        __send__("render_#{params[:action]}".to_sym, __send__("perform_#{params[:action]}".to_sym, __send__("params_for_#{params[:action]}".to_sym)))
      end

      def query_for_index
        @relation = @model_class.all
      end

      def params_for_index
        @aparams = params
      end

      def perform_index(aparams)
        @relation = __send__("query_for_#{params[:action]}".to_sym)

        short_circuit_result = execute_functions(:index_filters, :after_index_filters)
        return short_circuit_result if short_circuit_result

        instance_variable_set(@model_at_plural_name_sym, @relation.to_a)
      end

      def render_index(records)
        respond_with records, (__send__("render_#{params[:action]}_options".to_sym, records) || {}).merge(self.action_to_valid_render_options[params[:action].to_sym] || {})
      end

      def render_index_options(records)
        {}
      end
    end
  end
end
