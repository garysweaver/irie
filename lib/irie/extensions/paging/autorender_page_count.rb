module Irie
  module Extensions
    module Paging
      # Standard rendering of index page count in all formats except html so you don't need views for them.
      module AutorenderPageCount
        extend ::ActiveSupport::Concern
        ::Irie.available_extensions[:autorender_page_count] = '::' + AutorenderPageCount.name

        protected

        def autorender_page_count(options={}, &block)
          logger.debug("Irie::Extensions::Paging::AutorenderPageCount.autorender_page_count") if Irie.debug?
          index! do |format|
            format.any { render request.format.symbol => { page_count: @page_count }, status: 200 }
          end
        end
        
      end
    end
  end
end
