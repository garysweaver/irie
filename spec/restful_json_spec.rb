require 'spec_helper'

class Foobar < ActiveRecord::Base
  include RestfulJson::Model
end

class FoobarsController < ActionController::Base
  include RestfulJson::Controller
  acts_as_restful_json
  can_filter_by :foo_id
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
  supports_functions :count
  order_by [{:foo_date => :asc}, {:bar_date => :desc}]
end

Rails.application.routes.draw do
  resource :foobars
end

describe FoobarsController do
  describe "GET index" do
    it 'returns foobars in correct order' do
      Foobar.delete_all
      expected = []
      10.times do |c|
        expected << Foobar.create(foo_id: c, foo_date: Time.new(2012 - c), bar_date: Time.new(2012 + c))
      end
      get :index
      assigns(:foobars).should eq(expected.reverse)
    end
  end
end
