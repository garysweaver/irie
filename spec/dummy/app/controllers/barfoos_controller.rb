class BarfoosController < ApplicationController

  include ::Actionizer::Controller

  respond_to :json

  include_actions :all
  include_extensions(*Actionizer.available_extensions.keys)
  
  index_query ->(q) {q.where(:status => 2)}
  query_includes :foo

private

  def barfoo_params
    params.permit(:id)
  rescue => e
    puts "Problem with barfoo_params: #{params.inspect}"
    raise e
  end
end
