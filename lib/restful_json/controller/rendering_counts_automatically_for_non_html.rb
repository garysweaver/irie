# Standard rendering of index counts in all formats except html so you don't need views for them.
module RestfulJson
  module Controller
    module RenderingCountsAutomaticallyForNonHtml
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      # Note: query_for with non-index action or list_action will alias_method this and all other index-related methods.
      def render_index_count(count)
        @count = count
        # use implicit rendering for html
        return render "#{params[:action]}_count" if request.format.html?
        respond_to do |format|
          format.any { render request.format.symbol => { count: count } }
        end
      end

      # Note: query_for with non-index action or list_action will alias_method this and all other index-related methods.
      def render_index_page_count(count)
        @page_count = count
        # use implicit rendering for html
        return render "#{params[:action]}_page_count" if request.format.html?
        respond_to do |format|
          format.any { render request.format.symbol => { page_count: count } }
        end
      end

    end
  end
end
