module Irie
  module Extensions
    # Allows limiting of the number of records returned by the index query.
    module Limit
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:limit] = '::' + Limit.name

      included do
        include ::Irie::ParamAliases
      end

      def index_filters
        logger.debug("Irie::Extensions::Limit.index_filters") if Irie.debug?
        aliased_params(:limit).each {|param_value| collection.limit!(param_value)}
        defined?(super) ? super : collection
      end
    end
  end
end
