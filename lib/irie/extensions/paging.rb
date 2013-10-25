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
        page_param_value = first_aliased_param_value(:page)
        unless page_param_value.nil?
          page = page_param_value.to_i
          page = 1 if page < 1
          collection.offset!((self.number_of_records_in_a_page * (page - 1)).to_s).limit!(self.number_of_records_in_a_page.to_s)
        end

        defined?(super) ? super : collection
      end

      def index
        logger.debug("Irie::Extensions::Paging.index(#{count.inspect})") if Irie.debug?
        return super if first_aliased_param_value(:page_count)
        @page_count = collection.count
        respond_to(:autorender_count) ? autorender_count(@page_count) : @page_count
      end
    end
  end
end
