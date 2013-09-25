module Actionizer
  module Extensions
    # Allows limiting of the number of records returned by the index query.
    module Limit
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:limit] = '::' + Limit.name

      included do
        include ::Actionizer::ParamAliases
      end

      def index_filters
        aliased_params(:limit).each {|param_value| @relation.limit!(param_value)}
        super if defined?(super)
      end
    end
  end
end
