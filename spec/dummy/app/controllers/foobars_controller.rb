class FoobarsController < ApplicationController
  include RestfulJson::DefaultController
  
  can_filter_by :foo_id
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
  supports_functions :count
  order_by [{:foo_id => :desc}]
  #TODO: make this prove something and not just execute the code
  includes_for :create, :index, are: [:need_a_test_for_this]
  includes_for :update, are: [:need_a_test_for_this]
end
