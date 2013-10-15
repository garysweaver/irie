module Actionizer
  module Extensions
    # Allowing setting `@count` with the count of the records in the index query.
    module Count
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:count] = '::' + Count.name

      included do
        include ::Actionizer::ParamAliases
      end

      def after_index_filters
        logger.debug("Actionizer::Extensions::Count.after_index_filters") if Actionizer.debug?
        if aliased_param(:count)
          @count = @relation.count.to_i
          @action_result = render_index_count
          throw :action_break
        end

        super if defined?(super)
      end

      def render_index_count
        logger.debug("Actionizer::Extensions::Count.render_index_count") if Actionizer.debug?
        render 'index_count'
      end

    end
  end
end
