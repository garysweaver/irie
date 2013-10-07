class FoobarsController < ApplicationController
  
  include ::Actionizer::Controller
  
  respond_to :json

  include_actions :all
  include_extensions :rfc2616, :authorizing
  
  define_param renamed_foo_id: :foo_id
  can_filter_by_query a_query: ->(q, param_value) { q.where(foo_id: param_value) }
  can_filter_by :foo_id
  can_filter_by :renamed_foo_id
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt]
  can_filter_by :bar, through: {foo: {bar: :open_hours}}
  can_order_by :foo_id

  default_filter_by :renamed_foo_id, not_eq: 3
  default_order_by [{foo_id: :desc}]
  query_includes_for :create, :index, are: [:foo]
  query_includes_for :update, are: [:bar]

private

  def foobar_params
    params.require(:foobar).permit(:id, foo_attributes: [:id, :code])

  #rescue => e
  #  puts "Problem with foobar_params: #{params.inspect}"
  #  raise e
  end
end
