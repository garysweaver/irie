module Actionizer
  module Extensions
    module Distinct
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::FunctionParamAliasing
      end

      def index_filters
        @relation.distinct! if aliased_param(:distinct)
        super if defined?(super)
      end
    end
  end
end
