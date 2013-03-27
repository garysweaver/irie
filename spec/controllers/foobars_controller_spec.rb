require 'rails'
require 'spec_helper'
require 'foobars_controller'

#Dummy::Application.routes.draw do
#  resource :foobars
#end

routes= Rails.application.routes.routes.map do |route|
  puts "#{route.name}, path: #{route.path}, controller: #{route.defaults[:controller].inspect}, action: #{route.defaults[:action].inspect}"
end

describe FoobarsController do
  describe "GET index" do
    it 'returns foobars in correct order' do
      Foobar.delete_all
      expected = []
      10.times do |c|
        expected << Foobar.create(foo_id: c, foo_date: Time.new(2012 - c), bar_date: Time.new(2012 + c))
      end
      get :index, :format => :json
      assigns(:foobars).should eq(expected.reverse)
    end
  end
end
