require 'rails'
require 'spec_helper'

describe BarfoosController do
  render_views
  
  before(:each) do
    BarfoosController.test_role = 'admin'
  end

  describe "GET index" do
    it 'fails authorization' do
      barfoo = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka", foobars: [Foobar.create])
      BarfoosController.test_role = 'guest'
      begin        
        put :update, id: barfoo.id, foo_id: '', format: :json
        fail 'Expected CanCan::AccessDenied'
      rescue CanCan::AccessDenied
      end
    end

    it 'returns barfoos with correct fields' do
      begin
        Barfoo.delete_all
        expected = []

        10.times do |c|
          expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}", foobars: [Foobar.create])
        end
        get :index, format: :json
        # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
        @response.body.should eq("{\"check\":\"barfoos-index: size=3, statuses=borscht 2,borscht 5,borscht 8\"}")
      end
    end
  end
end
