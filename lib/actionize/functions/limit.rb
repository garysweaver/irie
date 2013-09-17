module Actionize
  module Functions
    module Limit
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        function_for :index_filters, name: 'Actionize::Functions::Count' do
          aliased_params(:limit).each {|param_value| @relation.limit!(param_value)}
            
          nil
        end
      end
    end
  end
end
