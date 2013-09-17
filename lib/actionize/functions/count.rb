module Actionize
  module Functions
    module Count
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        function_for :after_index_filters, name: 'Actionize::Functions::Count' do
          if aliased_param(:count)
            # explicit return to return from calling method of the proc
            count = @relation.count.to_i
            return __send__("render_#{params[:action]}_count".to_sym, count)
          end          
        end
      end

      def render_index_count(count)
        @count = count
        render "#{params[:action]}_count"
      end
    end
  end
end
