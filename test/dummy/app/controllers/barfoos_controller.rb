class BarfoosController < ApplicationController

  respond_to :json
  inherit_resources

  actions :all
  # among other things this checks that authorizing called after index_query still works
  extensions :all
  
  index_query ->(q) {q.where(:status => 2)}
  query_includes :foo

private

  def permitted_params
    params.permit(:id)
  end
end
