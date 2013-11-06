module Example
  module Alpha
    class FoobarsController < ApplicationController
      
      respond_to :json
      inherit_resources

      actions :all
      extensions :nil_params
      # see: https://github.com/ryanb/cancan/wiki/Inherited-Resources
      load_and_authorize_resource
      
      can_filter_by_query a_query: ->(q, param_value) { q.where(foo_id: param_value) }
      can_filter_by :foo_id
      can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt]
      can_filter_by :open_hours, through: {foo: {bar: :open_hours}}

      define_params renamed_foo_id: :foo_id
      can_filter_by :renamed_foo_id
      default_filter_by :renamed_foo_id, not_eq: 3

      # foo_id,+bar_code,-renamed_foo_id
      can_order_by :foo_id
      can_order_by :renamed_foo_id
      can_order_by :bar_code, through: {foo: {bar: :code}}
      
      default_order_by [{foo_id: :desc}, :renamed_foo_id, :foo_date, bar_code: :asc]

      query_includes :foo
      query_includes_for :update, are: {foo: [:bar]}

    private

      def build_resource_params
        #TODO: fix. the problem is that the wrapped param should be optional for 'new', but there
        # isn't a concept of an "optional require" in S.P. yet.
        [params.permit(:id, :format, foobar: [:id, :foo_id, foo_attributes: [:id, :code]])[:foobar]]
      end
    end
  end
end
