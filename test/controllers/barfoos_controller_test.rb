require 'test_helper'
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

class TestBarfoosController < ActionController::TestCase

  def setup
    @controller = BarfoosController.new

    DatabaseCleaner.start
    Actionizer.update_should_return_entity = false
    $test_role = 'admin'
    #@request.env['CONTENT_TYPE'] = 'application/json'
  end

  def teardown
    DatabaseCleaner.clean
  end

  test 'index fails authorization' do
    barfoo = Barfoo.create(status: 1, favorite_food: "borscht", favorite_drink: "vodka", foobars: [Foobar.create])
    $test_role = 'guest'
    json_index
    # use of accessible_by in Authorizing should filter query completely so nothing comes back
    assert_equal "{\"check\":\"barfoos-index: size=0, statuses=\"}", response.body
  end

  test 'index returns barfoos via index query' do
    expected = []

    10.times do |c|
      expected << Barfoo.create(status: (c % 3), favorite_food: "borscht #{c}", favorite_drink: "vodka #{c}", foobars: [Foobar.create])
    end
    json_index
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    assert_equal "{\"check\":\"barfoos-index: size=3, statuses=borscht 2,borscht 5,borscht 8\"}", response.body
  end
end
