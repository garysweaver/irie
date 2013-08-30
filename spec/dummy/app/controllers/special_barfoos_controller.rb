class SpecialBarfoosController < ApplicationController
  include RestfulJson::Controller
  
  # make it use Barfoo class under the hood
  self.model_class = Barfoo

  query_for :some_action, is: ->(t,q) {q.where(:status => 2)}

private

  def barfoo_params
    params.permit(:id, :favorite_food)
  rescue => e
    puts "Problem with params: #{params.inspect}\n\n#{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end
end
