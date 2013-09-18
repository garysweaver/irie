module Actionizer
  module Extensions
    module Count
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::FunctionParamAliasing
      end

      def after_index_filters
        if aliased_param(:count)
          # explicit return to return from calling method of the proc
          count = @relation.count.to_i
          @action_result = __send__("render_#{params[:action]}_count".to_sym, count)
          throw :action_break
        end

        super if defined?(super)
      end

      def render_index_count(count)
        @count = count
        render "#{params[:action]}_count"
      end

    end
  end
end

