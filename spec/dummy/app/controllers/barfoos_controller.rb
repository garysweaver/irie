class BarfoosController < ApplicationController
  include RestfulJson::Controller
  query_for :some_action, is: ->(t,q) {q.where(:status => 2)}
  including :foo
end

