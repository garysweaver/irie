class BarfoosController < ApplicationController

  include ::Actionizer::Controller

  respond_to :json

  include_actions :all
  include_extensions(*Actionizer.available_extensions.keys)
  
  query_for some_action: ->(q) {q.where(:status => 2)}
  query_includes :foo
end
