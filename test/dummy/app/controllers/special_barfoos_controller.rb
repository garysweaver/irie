class SpecialBarfoosController < ApplicationController

  include ::Actionizer::Controller
  
  respond_to :json

  include_actions :all
  include_extensions :all
  
  # make it use Barfoo class under the hood
  defaults resource_class: Barfoo

  index_query ->(q) {q.where(:status => 2)}

private

  def barfoo_params
    params.require(:barfoo).permit(:id, :favorite_food)
  end
end
