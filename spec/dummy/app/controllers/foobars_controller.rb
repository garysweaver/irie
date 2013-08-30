class FoobarsController < ApplicationController
  include RestfulJson::Controller
  
  can_filter_by :foo_id
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
  supports_functions :count
  order_by [{:foo_id => :desc}]
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
