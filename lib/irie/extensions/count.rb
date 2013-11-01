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
        super(options, &block) unless first_aliased_param_value(:count)
        @count = collection.count
        respond_to?(:autorender_count) ? autorender_count(options, &block) : super(options, &block)
      end if respond_to?(:index)

    end
  end
end
