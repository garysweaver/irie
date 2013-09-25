module Actionizer
  module Extensions
    # Allows use of a lambda for the index query.
    module IndexQuery
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:index_query] = '::' + IndexQuery.name

      included do
        include ::Actionizer::ParamAliases

        class_attribute(:custom_index_query, instance_writer: true) unless self.respond_to? :custom_index_query

        self.custom_index_query ||= nil
      end

      module ClassMethods
        # Specify a custom query. If action specified does not have a method, it will alias_method index to create a new action method with that query, e.g.
        #   index_query ->(q) { q.where(:status_code => 'green') },
        def index_query(query)
          self.custom_index_query = query
        end
      end

      def query_for_index
        @relation = self.custom_index_query ? self.custom_index_query.call(super) : super
      end
    end
  end
end
