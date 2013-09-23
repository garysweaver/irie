# Standard rendering of index counts in all formats except html so you don't need views for them.
# This only works if include it after either/both include order/paging functions, since it overrides them.
module Actionizer
  module Extensions
    module Paging
      module AutorenderPageCount
        extend ::ActiveSupport::Concern
        Actionizer.available_extensions[:autorender_page_count] = '::' + AutorenderPageCount.name

        def render_index_page_count(count)
          @page_count = count
          respond_to do |format|
            format.html { render "#{params[:action]}_page_count" }
            format.any { render request.format.symbol => { page_count: count } }
          end
        end
        
      end
    end
  end
end
