class BarfoosController < ApplicationController
  include RestfulJson::DefaultController
  
  query_for :some_action, is: ->(t,q) {q.where(:status => 2)}
  serialize_action :some_action, with: SimpleBarfooSerializer
end

