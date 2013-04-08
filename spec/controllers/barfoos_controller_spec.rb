require 'rails'
require 'spec_helper'

describe BarfoosController do
  describe "GET index" do
    it 'returns barfoos with correct fields' do
      orig = RestfulJson.avoid_respond_with
      RestfulJson.avoid_respond_with = true
      begin
        Barfoo.delete_all
        expected = []
        10.times do |c|
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht", favorite_drink: "vodka")
        end
        get :some_action, :format => :json
        assert_match '{"barfoos":[{"id":3,"favorite_food":"borscht"},{"id":6,"favorite_food":"borscht"},{"id":9,"favorite_food":"borscht"}]}', @response.body
      ensure
        RestfulJson.avoid_respond_with = orig
      end
    end
  end
end
