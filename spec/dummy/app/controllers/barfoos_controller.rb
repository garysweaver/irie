class BarfoosController < ApplicationController
  # test deprecated way to include RestfulJson::DefaultController
  acts_as_restful_json
  
  query_for :some_action, is: ->(t,q) {q.where(:status => 2)}
  serialize_action :some_action, with: SimpleBarfooSerializer
end
