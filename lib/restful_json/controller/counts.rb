# Standard rendering of index counts in all formats except html so you don't need views for them.
module RestfulJson
  module Controller
    module Counts
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      # Note: query_for with non-index action or list_action will alias_method this and all other index-related methods.
      def render_index_count(count)
        render_count(count)
      end

      # Note: query_for with non-index action or list_action will alias_method this and all other index-related methods.
      def render_index_page_count(count)
        render_count(count)
      end

      def render_count(count)
        @count = count
        content_type = request.formats.first.to_s.reverse.split('/')[0].split('-')[0].reverse
        # use implicit rendering for html
        return render "#{params[:action]}_count" if request.format.html?
        respond_to do |format|
          format.any { render content_type.to_sym => { count: count } }
        end
      end

    end
  end
end
