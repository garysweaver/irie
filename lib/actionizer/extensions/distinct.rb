module Actionizer
  module Extensions
    # Allows the ability to return distinct records in the index query.
    module Distinct
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:distinct] = '::' + Distinct.name

      included do
        include ::Actionizer::ParamAliases
      end

      def index_filters
        logger.debug("Actionizer::Extensions::Distinct.index_filters") if Actionizer.debug?
        @relation.distinct! if aliased_param(:distinct)
        super if defined?(super)
      end
    end
  end
end
