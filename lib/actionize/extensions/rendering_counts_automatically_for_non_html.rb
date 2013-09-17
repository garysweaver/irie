# Standard rendering of index counts in all formats except html so you don't need views for them.
# This only works if include it after either/both include order/paging functions, since it overrides them.
module Actionize
  module Extensions
    module RenderingCountsAutomaticallyForNonHtml
      extend ::ActiveSupport::Concern 
      
      def render_index_count(count)
        @count = count
        respond_to do |format|
          format.html { render "#{params[:action]}_count" }
          format.any { render request.format.symbol => { count: count } }
        end
      end

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
