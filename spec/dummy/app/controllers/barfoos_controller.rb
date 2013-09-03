class BarfoosController < ApplicationController
  include RestfulJson::Controller
  respond_to :json
  
  query_for :some_action, is: ->(t,q) {q.where(:status => 2)}
  including :foo
end

