module Irie
  module Extensions
    # Allowing setting `@count` with the count of the records in the index query.
    module Count
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:count] = '::' + Count.name

      included do
        include ::Irie::ParamAliases
      end
      
      def index(options={}, &block)
        logger.debug("Irie::Extensions::Count.index") if Irie.debug?
        return super(options, &block) unless aliased_param_specified?(:count)
        @count = collection.count
        return respond_to?(:autorender_count, true) ? autorender_count(options, &block) : index!(options, &block)
      end

    end
  end
end
