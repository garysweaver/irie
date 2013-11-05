module Example
  module Beta
    class FoobarsController < ApplicationController
      
      respond_to :json
      inherit_resources

      actions :index, :show, :create, :update
      extensions
      # see: https://github.com/ryanb/cancan/wiki/Inherited-Resources
      load_and_authorize_resource
      
      define_params renamed_foo_id: :foo_id
      can_filter_by_query a_query: ->(q, param_value) { q.where(foo_id: param_value) }
      can_filter_by :foo_id
      can_filter_by :renamed_foo_id
      can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt]
      can_filter_by :open_hours, through: {foo: {bar: :open_hours}}
      can_order_by :foo_id

      default_filter_by :renamed_foo_id, not_eq: 3
      default_order_by [{foo_id: :desc}]
      query_includes :foo
      query_includes_for :update, are: [:bar]

    private

      def build_resource_params
        [params.require(:foobar).permit(:id, :foo_id, foo_attributes: [:id, :code])]
      end
    end
  end
end
