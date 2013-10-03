require 'rails'
require 'spec_helper'

describe BarfoosController do
  render_views
  
  before(:each) do
    BarfoosController.test_role = 'admin'
    @request.env['CONTENT_TYPE'] = 'application/json'
  end

  it 'index fails authorization' do
    barfoo = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka", foobars: [Foobar.create])
    BarfoosController.test_role = 'guest'
    json_index
    # use of accessible_by in Authorizing should filter query completely so nothing comes back
    response.body.should eq("{\"check\":\"barfoos-index: size=0, statuses=\"}")
  end

  it 'index returns barfoos via index_query' do
    begin
      expected = []

      10.times do |c|
        expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}", foobars: [Foobar.create])
      end
      json_index
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      response.body.should eq("{\"check\":\"barfoos-index: size=3, statuses=borscht 2,borscht 5,borscht 8\"}")
    end
  end
end
