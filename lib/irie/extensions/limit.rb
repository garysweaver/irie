module Irie
  module Extensions
    # Allows limiting of the number of records returned by the index query.
    module Limit
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:limit] = '::' + Limit.name

      included do
        include ::Irie::ParamAliases
      end

      protected

      def collection
        logger.debug("Irie::Extensions::Limit.collection") if Irie.debug?
        object = super
        aliased_param_values(:limit).each {|param_value| object = object.limit(param_value)}

        logger.debug("Irie::Extensions::Limit.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)

        set_collection_ivar object
      end
    end
  end
end
