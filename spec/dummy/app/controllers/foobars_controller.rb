class FoobarsController < ApplicationController
  include RestfulJson::Controller
  include RestfulJson::Authorizing
  respond_to :json
  
  can_filter_by :a_query, with_query: ->(t, q, value) {q.where(foo_id: value)}
  can_filter_by :foo_id
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt]
  supports_functions :count
  can_order_by :foo_id
  default_order [{foo_id: :desc}]
  includes_for :create, :index, are: [:foo]
  includes_for :update, are: [:bar]

private

  def foobar_params
    params.permit(:id, :foo_id)
  rescue => e
    puts "Problem with params: #{params.inspect}"
    raise e
  end
end
