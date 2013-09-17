module Actionize
  module Functions
    module Offset
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        function_for :index_filters, name: 'Actionize::Functions::Count' do
          aliased_params(:offset).each {|param_value| @relation.offset!(param_value)}

          nil
        end
      end
    end
  end
end
