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
        result = assigns(:barfoos)
        result.count.should eq(3)
        result[0].favorite_food.should eq "borscht"
        result[0].status.should be_nil
        result[0].favorite_drink.should be_nil
      ensure
        RestfulJson.avoid_respond_with = orig
      end
    end
  end
end
