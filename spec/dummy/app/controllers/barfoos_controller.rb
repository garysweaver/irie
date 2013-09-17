class BarfoosController < ApplicationController

  include Actionize::Controller

  respond_to :json

  include_actions :all
  include_functions :all
  include_extensions :all
  
  query_for some_action: ->(q) {q.where(:status => 2)}
  query_includes :foo
end
