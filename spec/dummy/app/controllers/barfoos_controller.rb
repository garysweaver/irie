class BarfoosController < ApplicationController
  include RestfulJson::Controller
  include RestfulJson::Controller::UsingStandardRestRenderOptions
  respond_to :json
  
  query_for some_action: ->(q) {q.where(:status => 2)}
  including :foo
end
