class FoobarsController < ApplicationController
  include RestfulJson::DefaultController
  
  can_filter_by :foo_id
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
  supports_functions :count
  order_by [{:foo_date => :asc}, {:bar_date => :desc}]
end
