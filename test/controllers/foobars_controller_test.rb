require 'test_helper'
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

class TestFoobarsController < ActionController::TestCase

  def setup
    ::DatabaseCleaner.start
    ::Irie.update_should_return_entity = true
    @controller = FoobarsController.new
    $test_role = 'admin'

    10.times do |c|
      bar = Bar.where(id: c).first || Bar.create(id: c, code: "abc#{c}", open_hours: c)
      foo = Foo.create(id: c, code: "123#{c}", bar: bar)
      Foobar.create(foo: foo)
    end
  end

  def teardown
    DatabaseCleaner.clean
  end

  #[:foobar_url,
  #  :foobar_path,
  #  :foobars_url,
  #  :foobars_path,
  #  :edit_foobar_url,
  #  :edit_foobar_path,
  #  :new_foobar_url,
  #  :new_foobar_path].each do |m|
  #  test "has method #{m.to_s.inspect} for implicitly found model name" do
  #    assert @controller.respond_to? m
  #    assert_equal "#{m}", @controller.send(m)
  #  end
  #end

  test 'index returns foobars in default order with default filter' do
    expected = Foobar.all.reject!{|i|i.foo_id == 3} # default filter

    json_index
    assert_equal expected.reverse, assigns(:foobars)
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    assert_equal "{\"check\":\"foobars-index: size=#{expected.length}, ids=#{expected.reverse.collect{|f|f.id}.join(',')}\"}", response.body
  end

  test 'index returns foobars via through filter' do
    expected_foobar = Foobar.all.joins(foo: :bar).where(Bar.arel_table[:open_hours].eq(Bar.last.open_hours)).to_a.first

    json_index bar: Foobar.last.foo.bar.open_hours
    assert_equal 1, assigns(:foobars).length
    assert_equal "{\"check\":\"foobars-index: size=1, ids=#{expected_foobar.id}\"}", response.body
  end

  test 'index allows requested ascending order with default filter' do
    expected = Foobar.all.reject!{|i|i.foo_id == 3} # default filter

    json_index order: 'foo_id,+bar,-barfoo_id'
    assert_equal expected, assigns(:foobars)
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    first_id = expected.last.id-(expected.length - 1)
    last_id = expected.last.id
    assert_equal "{\"check\":\"foobars-index: size=#{expected.length}, ids=#{expected.collect{|f|f.id}.join(',')}\"}", response.body
  end

  test 'index returns foobars with simple filter' do
    expected = [Foobar.first]
    
    json_index foo_id: expected.first.foo.id
    assert_equal expected, assigns(:foobars)
  end

  test 'index returns foobars with defined param filter' do
    expected = [Foobar.first]

    json_index renamed_foo_id: expected.first.foo.id
    assert_equal expected, assigns(:foobars)
  end

  test 'index returns foobars with a query' do
    expected = [Foobar.first]

    json_index a_query: expected.first.foo.id
    assert_equal expected, assigns(:foobars)
  end

  test 'show assigns foobar' do
    foobar = Foobar.first

    json_show Foobar.primary_key => foobar.id
    assert assigns(:foobar).is_a?(Foobar)
    assert_equal response.status, 200, "show returned unexpected response code (got #{response.status}): #{response.body}"
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    assert_equal "{\"check\":\"foobars-show: #{foobar.id}\"}", response.body
  end

  test 'show fails for bad id' do
    begin
      json_show id: '9999999'
      fail('should have raised error')
    rescue => e
      assert_includes e.message, 'ound'
    end
  end

  test 'new assigns foobar' do
    json_new
    assert assigns(:foobar).is_a?(Foobar)
    assert_equal response.status, 200, "new returned unexpected response code (got #{response.status}): #{response.body}"
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    assert_equal "{\"check\":\"foobars-new: \"}", response.body
  end

  test 'new fails when cancan disallows user' do
    $test_role = 'nobody'

    begin
      json_new
      fail "cancan should not allow get" if response.status < 400
    rescue
    end
  end

  test 'edit assigns foobar' do
    foobar = Foobar.last
    json_edit Foobar.primary_key => foobar.id
    assert assigns(:foobar).is_a?(Foobar)
    assert_equal foobar.foo_id, assigns(:foobar).foo_id
  end

  test 'edit fails for bad id' do
    begin
      json_edit id: '9999999'
      fail "should have raised error"
    rescue
      assert_equal nil, assigns(:foobar)
    end
  end

  test 'edit fails when cancan disallows user' do
    $test_role = 'nobody'

    begin
      json_edit Foobar.primary_key => Foobar.last.id
      fail "cancan should not allow get" if response.status < 400
    rescue
    end
  end
  
  test 'create allowed for accepted params' do
    Foobar.delete_all
    before_count = Foobar.count
    foo = Foo.create
    json_create foobar: {foo_id: foo.id}
    assert_equal foo.id, Foobar.last.foo_id, "Expected created Foobar to have foo_id #{foo.id.inspect} but was #{Foobar.last.foo_id.inspect}"

    assert_equal before_count + 1, Foobar.count, "Didn't create Foobar"
    # RFC 2616 conformance checks. See: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1
    assert_equal "http://test.host/foobars/#{Foobar.last.id}", response.headers['Location'], "didn't include expected location header. was #{response.headers['Location']}"
    assert_equal "application/json; charset=utf-8", response.headers['Content-Type'], "didn't include expected content-type. was #{response.headers['Content-Type']}"
    assert_equal 201, response.status, "Bad response code (got #{response.status}): #{response.body}"
    
    assert_equal "{\"check\":\"foobars-create: #{Foobar.last.id}\"}", response.body
  end

  test 'create does not accept non-whitelisted params' do
    begin
      bar = Bar.create
      json_create foobar: {bar_id: bar.id}
      fail 'Expected ActionController::UnpermittedParameters to be raised for non-whitelisted param'
    rescue ActionController::UnpermittedParameters
      assert_equal [], Foobar.where(bar_id: bar.id), "should not have created with non-whitelisted param"
    end
  end

  test 'create does not create when cancan disallows user' do
    $test_role = 'nobody'

    start_count = Foobar.count
    begin
      json_create
      fail "cancan should not allow put" if response.status < 400
    rescue
    end
    assert_equal start_count, Foobar.count, "should not have created new record when CanCan disallows user"
  end

  test 'update allowed for accepted params' do
    foobar = Foobar.create(foo_id: Foo.last.id)
    foo_id = Foo.first.id
    json_update foobar: {Foobar.primary_key => foobar.id, foo_id: foo_id}
    # this controller is set to return entity on update, so will return 200 instead of 204
    assert_equal 200, response.status, "update returned unexpected response code (got #{response.status}): #{response.body}"
    assert_match "{\"check\":\"foobars-update: #{Foobar.last.id}\"}", response.body # no! need to fix
    assert_equal foo_id, Foobar.find(foobar.id).foo_id, "should have updated param"
  end

  test 'update does not accept non-whitelisted params' do
    orig_bar_id = Bar.last.id
    foobar = Foobar.create(bar_id: orig_bar_id)
    bar_id = Bar.first.id
    begin
      json_update foobar: {Foobar.primary_key => foobar.id, bar_id: bar_id}
      fail 'should have raised for non-whitelisted param'
    rescue ::ActionController::UnpermittedParameters
    end
    assert_equal orig_bar_id, Foobar.find(foobar.id).bar_id, "should not have updated with non-whitelisted param. expected #{orig_bar_id} but bar_id was #{Foobar.find(foobar.id).bar_id}"
  end

  test 'update does not accept whitelisted params when cancan disallows user' do
    $test_role = 'nobody'
    foobar = Foobar.create(foo_id: Foo.last.id)
    orig_foo_id = Foo.last.id
    foo_id = Foo.first.id
    begin
      json_update foobar: {Foobar.primary_key => foobar.id, foo_id: foo_id}
      fail "cancan should not allow put" if response.status < 400
    rescue
    end
    assert_equal foobar.foo_id, Foobar.find(foobar.id).foo_id, "should not have updated with whitelisted param when cancan disallows user"
  end

  test 'update fails with HTTP 404 for missing record' do
    begin
      json_update foobar: {id: '9999999', food: ''}
      fail "should have raised error"
    rescue
      assert_nil Foobar.where(id: '9999999').first, "should not have created record"
    end
  end

  test 'destroy allowed for accepted id' do
    foobar = Foobar.create(foo_id: Foo.last.id)
    json_destroy id: foobar
    assert_match '', response.body
    assert_equal response.status, 200, "destroy returned unexpected response code (got #{response.status}): #{response.body}"
  end

  test 'destroy is idempotent and should not fail for missing record' do
    json_destroy id: '9999999'
    assert_match '', response.body
    assert_equal response.status, 200, "destroy returned unexpected response code (got #{response.status}): #{response.body}"
  end

  test 'destroy should fail with error if subclass of standard error' do
    begin
      foobar = Foobar.create(foo_id: Foo.last.id)
      # expect this to make destroy fail and reset in after hook
      $error_to_raise_on_next_save_or_destroy_only = SomeSubtypeOfStandardError.new("some type of standard error")
      json_destroy id: foobar.id
      fail "should have raised error"
    rescue
    end
  end
end
