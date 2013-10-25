module Irie
  module Extensions
    # Allowing setting `@count` with the count of the records in the index query.
    module Count
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:count] = '::' + Count.name

      def index
        logger.debug("Irie::Extensions::Count.index(#{count.inspect})") if Irie.debug?
        return super if permitted_params[:count]
        @count = get_collection_ivar.count
        respond_to(:autorender_count) ? autorender_count(@count) : @count
      end

    end
  end
end
