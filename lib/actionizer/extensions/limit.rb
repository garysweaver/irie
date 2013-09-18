module Actionizer
  module Extensions
    module Limit
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::FunctionParamAliasing
      end

      def index_filters
        aliased_params(:limit).each {|param_value| @relation.limit!(param_value)}
        super if defined?(super)
      end
    end
  end
end
