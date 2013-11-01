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
        logger.debug("Irie::Extensions::Offset.collection") if Irie.debug?
        object = super
        # convert to relation if model class, so we can use bang (offset!) method
        object = object.all unless object.is_a?(ActiveRecord::Relation)
        aliased_param_values(:offset).each {|param_value| object.offset!(param_value)}

        logger.debug("Irie::Extensions::Offset.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)

        object
      end
    end
  end
end
