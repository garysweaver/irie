module Irie
  module Extensions
    # Allowing offsetting (skipping) records that would be returned by the index query.
    module Offset
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:offset] = '::' + Offset.name

      included do
        include ::Irie::ParamAliases
      end

      def collection
        logger.debug("Irie::Extensions::Offset.index_filters") if Irie.debug?
        aliased_param_values(:offset).each {|param_value| collection.offset!(param_value)}
        defined?(super) ? super : collection
      end
    end
  end
end
