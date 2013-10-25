module Irie
  module Extensions
    # Allowing setting `@count` with the count of the records in the index query.
    module Count
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:count] = '::' + Count.name

      included do
        include ::Irie::ParamAliases
      end

      def after_index_filters
        logger.debug("Irie::Extensions::Count.after_index_filters") if Irie.debug?
        if aliased_param(:count)
          @count = get_collection_ivar.count.to_i
          @action_result = render_index_count
          throw :action_break
        end

        defined?(super) ? super : get_collection_ivar
      end

      def render_index_count
        logger.debug("Irie::Extensions::Count.render_index_count") if Irie.debug?
        render 'index_count'
      end

    end
  end
end
