module Actionizer
  module Extensions
    module Paging
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::FunctionParamAliasing

        class_attribute :number_of_records_in_a_page, instance_writer: true

        self.number_of_records_in_a_page = Actionizer.number_of_records_in_a_page
      end

      def index_filters
        if (param_value = aliased_param(:page))
          page = param_value.to_i
          page = 1 if page < 1
          @relation.offset!((self.number_of_records_in_a_page * (page - 1)).to_s)
          @relation.limit!(self.number_of_records_in_a_page.to_s)
        end
        super if defined?(super)
      end

      def after_index_filters
        if aliased_param(:page_count)
          # explicit return to return from calling method of the proc
          count_value = @relation.count.to_i
          page_count = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
          @action_result = __send__("render_#{params[:action]}_page_count".to_sym, page_count)
          throw :action_break
        end
        super if defined?(super)
      end

      def render_index_page_count(count)
        @page_count = count
        render "#{params[:action]}_page_count"
      end
    end
  end
end
