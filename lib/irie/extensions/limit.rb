module Irie
  module Extensions
    # Allows limiting of the number of records returned by the index query.
    module Limit
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:limit] = '::' + Limit.name

      included do
        include ::Irie::ParamAliases
      end

      def collection
        logger.debug("Irie::Extensions::Limit.collection") if Irie.debug?
        object = super
        # convert to relation if model class, so we can use bang (limit!) method
        object = object.all unless object.is_a?(ActiveRecord::Relation)
        aliased_param_values(:limit).each {|param_value| object.limit!(param_value)}

        logger.debug("Irie::Extensions::Limit.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)
        
        object
      end
    end
  end
end
