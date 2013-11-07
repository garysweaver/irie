module Irie
  module Extensions
    # Allowing offsetting (skipping) records that would be returned by the index query.
    module Offset
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:offset] = '::' + Offset.name

      included do
        include ::Irie::ParamAliases
      end

      protected

      def collection
        logger.debug("Irie::Extensions::Offset.collection") if Irie.debug?
        object = super
        aliased_params(:offset).each {|param_value| object = object.offset(param_value)}

        logger.debug("Irie::Extensions::Offset.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)

        set_collection_ivar object
      end
    end
  end
end
