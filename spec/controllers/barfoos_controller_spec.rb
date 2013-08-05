require 'rails'
require 'spec_helper'

describe BarfoosController do
  before(:each) do
    @orig = RestfulJson.avoid_respond_with
    RestfulJson.avoid_respond_with = false
    BarfoosController.test_role = 'guest'
  end

  describe "GET index" do
    it 'returns barfoos with correct fields' do
      orig = RestfulJson.avoid_respond_with
      RestfulJson.avoid_respond_with = true
      begin
        Barfoo.delete_all
        expected = []

        10.times do |c|
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}", foobars: [Foobar.create])
        end
        get :some_action, :format => :json
        # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
        @response.body.should be_json_eql('{"barfoos":[{"favorite_food":"borscht 2","foobars":[{"bar":null,"bar_date":null,"foo":null,"foo_date":null}]},{"favorite_food":"borscht 5","foobars":[{"bar":null,"bar_date":null,"foo":null,"foo_date":null}]},{"favorite_food":"borscht 8","foobars":[{"bar":null,"bar_date":null,"foo":null,"foo_date":null}]}]}')
      ensure
        RestfulJson.avoid_respond_with = orig
      end
    end
  end
end
