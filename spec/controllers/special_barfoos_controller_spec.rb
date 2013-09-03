require 'rails'
require 'spec_helper'

describe SpecialBarfoosController do
  render_views

  before(:each) do
    SpecialBarfoosController.test_role = 'admin'
  end

  describe "GET index" do
    it 'returns special barfoos with correct fields' do
      Barfoo.delete_all
      expected = []
      10.times do |c|
        expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}")
      end
      get :some_action, format: :json
      @response.body.should eq("{\"check\":\"special_barfoos-index: size=3, ids=borscht 2,borscht 5,borscht 8\"}")
    end
  end

  describe "PUT update" do
    it 'allowed for accepted params' do
      Barfoo.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka")
      favorite_food = "test"
      put :update, Foobar.primary_key => b.id, favorite_food: favorite_food, format: :json
      # this really should be 204. :( not our problem
      response.status.should eq(204), "update failed (got #{response.status}): #{response.body}"
      assert_match '', @response.body
      Barfoo.where(favorite_food: favorite_food).should_not be_empty, "should have updated param"
    end

    it 'responds if doesn\'t validate' do
      Barfoo.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka")
      favorite_food = "." * 51 # max length 15 in model
      put :update, Foobar.primary_key => b.id, favorite_food: favorite_food, format: :json
      response.status.should eq(422), "update failed (got #{response.status}): #{response.body}"
      @response.body.should be_json_eql('{"errors":{"favorite_food":["is too long (maximum is 15 characters)"]}}')
    end

    it 'does not accept non-whitelisted params' do
      Barfoo.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka")
      favorite_drink = SecureRandom.urlsafe_base64
      put :update, Barfoo.primary_key => b.id, favorite_drink: favorite_drink, format: :json
      # this really should be 204. :( not our problem
      response.status.should eq(204), "update failed (got #{response.status}): #{response.body}"
      assert_match '', @response.body
      Barfoo.where(favorite_drink: favorite_drink).should be_empty, "should not have updated with non-whitelisted param"
    end
  end
end
