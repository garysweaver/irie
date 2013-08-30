require 'rails'
require 'spec_helper'

describe BarfoosController do
  render_views
  
  before(:each) do
    BarfoosController.test_role = 'guest'
  end

  describe "GET index" do
    it 'returns barfoos with correct fields' do
      begin
        Barfoo.delete_all
        expected = []

        10.times do |c|
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}", foobars: [Foobar.create])
        end
        get :some_action, format: :json
        # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
        @response.body.should eq("{\"check\":\"barfoos-some_action: size=3, ids=borscht 2,borscht 5,borscht 8\"}")
      end
    end
  end
end
