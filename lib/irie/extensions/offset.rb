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
        aliased_params(:offset).each {|param_value| get_collection_ivar.offset!(param_value)}
        defined?(super) ? super : get_collection_ivar
      end
    end
  end
end
