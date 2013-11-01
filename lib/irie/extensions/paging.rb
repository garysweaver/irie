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

      def collection
        logger.debug("Irie::Extensions::Paging.collection") if Irie.debug?
        object = super
        # convert to relation if model class, so we can use bang methods (offset! and limit!)
        object = object.all unless object.is_a?(ActiveRecord::Relation)
        page_param_value = first_aliased_param_value(:page)
        unless page_param_value.nil?
          page = page_param_value.to_i
          page = 1 if page < 1
          object.offset!((self.number_of_records_in_a_page * (page - 1)).to_s).limit!(self.number_of_records_in_a_page.to_s)
        end

        logger.debug("Irie::Extensions::Paging.collection: relation.to_sql so far: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)

        object
      end

    end
  end
end
