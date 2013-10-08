require 'rails'
require 'spec_helper'

describe SpecialBarfoosController do
  before(:each) do
    SpecialBarfoosController.test_role = 'admin'
    @request.env['CONTENT_TYPE'] = 'application/json'
  end

  it 'index returns special barfoos with correct fields' do
    expected = []
    10.times do |c|
      expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}")
    end
    json_index
    response.body.should eq("{\"check\":\"special_barfoos-index: size=3, ids=borscht 2,borscht 5,borscht 8\"}")
  end

  it 'update allowed for accepted params' do
    b = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka")
    favorite_food = "test"
    json_update barfoo: {Foobar.primary_key => b.id, favorite_food: favorite_food}
    # returning 204 because controller by default won't return entity with update per RFC 2616: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1
    response.status.should eq(204), "unexpected code from update (got #{response.status}): #{response.body}"
    assert_match '', response.body
    Barfoo.where(favorite_food: favorite_food).should_not be_empty, "should have updated param"
  end

  it 'update responds if doesn\'t validate' do
    b = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka")
    favorite_food = "." * 51 # max length 15 in model
    json_update barfoo: {Foobar.primary_key => b.id, favorite_food: favorite_food}
    response.status.should eq(422), "update failed (got #{response.status}): #{response.body}"
    response.body.should be_json_eql('{"errors":{"favorite_food":["is too long (maximum is 15 characters)"]}}')
  end

  it 'update does not accept non-whitelisted params' do
    b = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka")
    favorite_drink = SecureRandom.urlsafe_base64
    begin
      json_update barfoo: {Barfoo.primary_key => b.id, favorite_drink: favorite_drink}
      fail "should have raised error when attempted to put resource with unpermitted attribute value"
    rescue
      Barfoo.where(favorite_drink: favorite_drink).should be_empty, "should not have updated with non-whitelisted param"
    end
  end
end
