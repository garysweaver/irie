module Actionizer
  module Actions
    module Index
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::Actions::Base
      end

      def index_filters
        super if defined?(super)
      end

      def after_index_filters
        super if defined?(super)
      end

      # The controller's index (list) method to list resources.
      def index
        return catch(:action_break) do
          __send__("render_#{params[:action]}".to_sym, __send__("perform_#{params[:action]}".to_sym, __send__("params_for_#{params[:action]}".to_sym)))
        end || @action_result
      end

      def query_for_index
        @relation = @model_class.all
      end

      def params_for_index
        @aparams = params
      end

      def perform_index(aparams)
        @relation = __send__("query_for_#{params[:action]}".to_sym)
        index_filters
        after_index_filters
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
