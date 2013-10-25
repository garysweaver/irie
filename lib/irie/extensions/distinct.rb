module Irie
  module Extensions
    # Allows the ability to return distinct records in the index query.
    module Distinct
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:distinct] = '::' + Distinct.name

      included do
        include ::Irie::ParamAliases
      end

      def index_filters
        logger.debug("Irie::Extensions::Distinct.index_filters") if Irie.debug?
        get_collection_ivar.distinct! if aliased_param(:distinct)
        defined?(super) ? super : get_collection_ivar
      end
    end
  end
end
