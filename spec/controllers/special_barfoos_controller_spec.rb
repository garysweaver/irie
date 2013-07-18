require 'rails'
require 'spec_helper'

describe SpecialBarfoosController do
  before(:each) do
    @orig = RestfulJson.avoid_respond_with
    RestfulJson.avoid_respond_with = false
    SpecialBarfoosController.test_role = 'admin'
  end

  describe "GET index" do
    it 'returns special barfoos with correct fields' do
      orig = RestfulJson.avoid_respond_with
      RestfulJson.avoid_respond_with = true
      begin
        Barfoo.delete_all
        expected = []
        10.times do |c|
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}")
        end
        #require 'tracer'; Tracer.on do
        get :some_action, format: :json
        #end
        # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
        @response.body.should be_json_eql('{"special_barfoos":[{"id":"x","favorite_food":"borscht 2"},{"id":"x","favorite_food":"borscht 5"},{"id":"x","favorite_food":"borscht 8"}]}')
      ensure
        RestfulJson.avoid_respond_with = orig
      end
    end
  end

  describe "GET index" do
    it 'returns special barfoos in minimized format with correct fields' do
      orig = RestfulJson.avoid_respond_with
      RestfulJson.avoid_respond_with = true
      begin
        Barfoo.delete_all
        expected = []
        10.times do |c|
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}")
        end
        #require 'tracer'; Tracer.on do
        get :some_action, format: :json, minimize: true
        #end
        # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
        @response.body.should be_json_eql('[{"favorite_food":"borscht 2"},{"favorite_food":"borscht 5"},{"favorite_food":"borscht 8"}]')
      ensure
        RestfulJson.avoid_respond_with = orig
      end
    end
  end

  describe "PUT update" do
    it 'allowed for accepted params' do
      Barfoo.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Barfoo.create(status: 1, favorite_food: "borscht 1", favorite_drink: "vodka 1")
      favorite_food = "test"
      put :update, Foobar.primary_key => b.id, favorite_food: favorite_food, format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
      assert_match '', @response.body
      Barfoo.where(favorite_food: favorite_food).should_not be_empty, "should have updated param"
    end

    # AMS actually doesn't support Rails 3.1, but this is the only thing failing so far. It is either trying to use a serializer or not
    # wrapping json when there is a validation error.
    it 'responds if doesn\'t validate', :if => !(Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1) do
      Barfoo.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Barfoo.create(status: 1, favorite_food: "borscht 1", favorite_drink: "vodka 1")
      favorite_food = "." * 51 # max length 15 in model
      put :update, Foobar.primary_key => b.id, favorite_food: favorite_food, format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 422 : 422
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
      @response.body.should be_json_eql('{"errors":{"favorite_food":["is too long (maximum is 15 characters)"]}}')
    end

    it 'does not accept non-whitelisted params' do
      Barfoo.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Barfoo.create(status: 1, favorite_food: "borscht 1", favorite_drink: "vodka 1")
      favorite_drink = SecureRandom.urlsafe_base64
      put :update, Barfoo.primary_key => b.id, favorite_drink: favorite_drink, format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
      assert_match '', @response.body
      Barfoo.where(favorite_drink: favorite_drink).should be_empty, "should not have updated with non-whitelisted param"
    end
  end
end
