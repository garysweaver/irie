# Allowing setting `@count` with the count of the records in the index query.
module Actionizer
  module Extensions
    module Count
      extend ::ActiveSupport::Concern
      Actionizer.available_extensions[:count] = '::' + Count.name

      included do
        include ::Actionizer::ParamAliases
      end

      def after_index_filters
        if aliased_param(:count)
          @count = @relation.count.to_i
          @action_result = render_index_count
          throw :action_break
        end

        super if defined?(super)
      end

      def render_index_count
        render 'index_count'
      end

    end
  end
end
