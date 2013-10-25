module Irie
  module Extensions
    # Allows use of a lambda for the index query.
    module IndexQuery
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:index_query] = '::' + IndexQuery.name

      included do
        require 'ostruct'

        include ::Irie::ParamAliases

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

      def begin_of_association_chain
        return super unless self.custom_index_query
        query_result = self.custom_index_query.call(resource_class)
        # we could try to make method_for_association_chain return nil, but I think inherited resources is assuming that
        # would only be falsey only it is a singleton controller without parents, and I can't guarantee that.
        if method_for_association_chain
          OpenStruct.new(method_for_association_chain => query_result)
        else
          query_result
        end
      end
    end
  end
end
