module Actionize
  module Functions
    module Distinct
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        function_for :index_filters, name: 'Actionize::Functions::Count' do
          @relation.distinct! if aliased_param(:distinct)

          nil
        end
      end
    end
  end
end
