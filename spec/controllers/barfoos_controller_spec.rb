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
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}")
        end
        get :some_action, :format => :json
        # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
        @response.body.should be_json_eql('{"barfoos":[{"id":"x","favorite_food":"borscht 2"},{"id":"x","favorite_food":"borscht 5"},{"id":"x","favorite_food":"borscht 8"}]}')
      ensure
        RestfulJson.avoid_respond_with = orig
      end
    end
  end
end
