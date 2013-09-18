module Actionizer
  module Extensions
    module Offset
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::FunctionParamAliasing
      end

      def index_filters
        aliased_params(:offset).each {|param_value| @relation.offset!(param_value)}
        super if defined?(super)
      end
    end
  end
end
