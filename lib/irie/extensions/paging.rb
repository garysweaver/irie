module Irie
  module Extensions
    # Allows paging of results.
    module Paging
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:paging] = '::' + Paging.name

      included do
        include ::Irie::ParamAliases

        class_attribute(:number_of_records_in_a_page, instance_writer: true) unless self.respond_to? :number_of_records_in_a_page

        self.number_of_records_in_a_page = ::Irie.number_of_records_in_a_page
      end

      protected

      def collection
        logger.debug("Irie::Extensions::Paging.collection") if Irie.debug?
        object = super
        page_param_value = first_aliased_param_value(:page)
        unless page_param_value.nil?
          page = page_param_value.to_i
          page = 1 if page < 1
          object = object.offset((self.number_of_records_in_a_page * (page - 1)).to_s)
          object = object.limit(self.number_of_records_in_a_page.to_s)
        end

        logger.debug("Irie::Extensions::Paging.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)

        set_collection_ivar object
      end

    end
  end
end
