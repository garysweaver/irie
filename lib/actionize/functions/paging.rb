module Actionize
  module Functions
    module Paging
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        class_attribute :number_of_records_in_a_page, instance_writer: true

        self.number_of_records_in_a_page = Actionize.number_of_records_in_a_page

        function_for :index_filters, name: 'Actionize::Functions::Count' do
          if (param_value = aliased_param(:page))
            page = param_value.to_i
            page = 1 if page < 1
            @relation.offset!((self.number_of_records_in_a_page * (page - 1)).to_s)
            @relation.limit!(self.number_of_records_in_a_page.to_s)
          end

          nil
        end

        function_for :after_index_filters, name: ::Actionize::Functions::Count do
          if aliased_param(:page_count)
            # explicit return to return from calling method of the proc
            count_value = @relation.count.to_i
            page_count = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
            return __send__("render_#{params[:action]}_page_count".to_sym, page_count)
          end

          nil
        end
      end

      def render_index_page_count(count)
        @page_count = count
        render "#{params[:action]}_page_count"
      end
    end
  end
end
