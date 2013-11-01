module Irie
  module Extensions
    # Allows the ability to return distinct records in the index query.
    module Distinct
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:distinct] = '::' + Distinct.name

      included do
        include ::Irie::ParamAliases
      end

      def collection
        logger.debug("Irie::Extensions::Distinct.collection") if Irie.debug?
        object = super
        object = object.distinct if first_aliased_param_value(:distinct)
        
        logger.debug("Irie::Extensions::Distinct.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)

        object
      end
    end
  end
end
