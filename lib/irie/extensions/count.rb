module Irie
  module Extensions
    # Allowing setting `@count` with the count of the records in the index query.
    module Count
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:count] = '::' + Count.name

      included do
        include ::Irie::ParamAliases
      end

      def index
        logger.debug("Irie::Extensions::Count.index(#{count.inspect})") if Irie.debug?
        return super if first_aliased_param_value(:count)
        @count = collection.count
        respond_to(:autorender_count) ? autorender_count(@count) : @count
      end

    end
  end
end
