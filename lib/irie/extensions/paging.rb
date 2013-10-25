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
        page_param_value = aliased_param(:page)
        unless page_param_value.nil?
          page = page_param_value.to_i
          page = 1 if page < 1
          get_collection_ivar.offset!((self.number_of_records_in_a_page * (page - 1)).to_s).limit!(self.number_of_records_in_a_page.to_s)
        end

        if aliased_param(:page_count)
          # explicit return to return from calling method of the proc
          count_value = get_collection_ivar.count.to_i
          @page_count = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
          @action_result = render_index_page_count
          throw :action_break
        end
        defined?(super) ? super : get_collection_ivar
      end

      def index
        logger.debug("Irie::Extensions::Paging.index(#{count.inspect})") if Irie.debug?
        return super if permitted_params[:page_count]
        @page_count = get_collection_ivar.count
        index! do |format|
          format.html { render "#{params[:action]}_page_count" }
          format.any { render request.format.symbol => { count: @page_count } }
        end
      end
    end
  end
end
