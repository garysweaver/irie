require 'rails'
require 'spec_helper'

class SomeSubtypeOfStandardError < StandardError
end

describe FoobarsController do
  before(:each) do
    FoobarsController.test_role = 'admin'
    @request.env['CONTENT_TYPE'] = 'application/json'

    10.times do |c|
      bar = Bar.where(id: c).first || Bar.create(id: c, code: "abc#{c}", open_hours: c)
      foo = Foo.create(id: c, code: "123#{c}", bar: bar)
      Foobar.create(foo: foo)
    end
  end

  it 'index returns foobars in default order with default filter' do
    expected = Foobar.all.reject!{|i|i.foo_id == 3} # default filter

    json_index
    assigns(:foobars).should eq(expected.reverse)
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    response.body.should eq("{\"check\":\"foobars-index: size=#{expected.length}, ids=#{expected.reverse.collect{|f|f.id}.join(',')}\"}")
  end

  it 'index returns foobars via through filter' do
    expected_foobar = Foobar.all.joins(foo: :bar).where(Bar.arel_table[:open_hours].eq(Bar.last.open_hours)).to_a.first

    json_index bar: Foobar.last.foo.bar.open_hours
    assigns(:foobars).length.should eq(1)
    response.body.should eq("{\"check\":\"foobars-index: size=1, ids=#{expected_foobar.id}\"}")
  end

  it 'index allows requested ascending order with default filter' do
    expected = Foobar.all.reject!{|i|i.foo_id == 3} # default filter

    json_index order: 'foo_id,+bar,-barfoo_id'
    assigns(:foobars).should eq(expected)
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    first_id = expected.last.id-(expected.length - 1)
    last_id = expected.last.id
    response.body.should eq("{\"check\":\"foobars-index: size=#{expected.length}, ids=#{expected.collect{|f|f.id}.join(',')}\"}")
  end

  it 'index returns foobars with simple filter' do
    expected = [Foobar.first]
    
    json_index foo_id: expected.first.foo.id
    assigns(:foobars).should eq(expected)
  end

  it 'index returns foobars with defined param filter' do
    expected = [Foobar.first]

    json_index renamed_foo_id: expected.first.foo.id
    assigns(:foobars).should eq(expected)
  end

  it 'index returns foobars with a query' do
    expected = [Foobar.first]

    json_index a_query: expected.first.foo.id
    assigns(:foobars).should eq(expected)
  end

  it 'show assigns foobar' do
    foobar = Foobar.first

    json_show Foobar.primary_key => foobar.id
    assigns(:foobar).is_a?(Foobar).should be
    response.status.should eq(200), "show failed (got #{response.status}): #{response.body}"
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    response.body.should eq("{\"check\":\"foobars-show: #{foobar.id}\"}")
  end

  it 'show fails for bad id' do
    begin
      json_show id: '9999999'
      fail('should have raised error')
    rescue => e
      e.message.should include('ound')
    end
  end

  it 'new assigns foobar' do
    get :new, format: :json
    assigns(:foobar).is_a?(Foobar).should be
    response.status.should eq(200), "new failed (got #{response.status}): #{response.body}"
    # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
    response.body.should eq("{\"check\":\"foobars-new: \"}")
  end

  it 'new fails when cancan disallows user' do
    FoobarsController.test_role = 'nobody'

    begin
      json_new
      fail "cancan should not allow get" if response.status < 400
    rescue
    end
  end

  it 'edit assigns foobar' do
    foobar = Foobar.last
    json_edit Foobar.primary_key => foobar.id
    assigns(:foobar).is_a?(Foobar).should be
    assigns(:foobar).foo_id.should eq(foobar.foo_id)
  end

  it 'edit fails for bad id' do
    begin
      json_edit id: '9999999'
      fail "should have raised error"
    rescue
      assigns(:foobar).should be_nil
    end
  end

  it 'edit fails when cancan disallows user' do
    FoobarsController.test_role = 'nobody'

    begin
      json_edit Foobar.primary_key => Foobar.last.id
      fail "cancan should not allow get" if response.status < 400
    rescue
    end
  end
  
  it 'create allowed for accepted params' do
    before_count = Foobar.count
    foo = Foo.create
    json_create foobar: {foo_id: foo.id}
    Foobar.count.should eq(before_count + 1), "Didn't create Foobar"
    response.status.should eq(201), "Bad response code (got #{response.status}): #{response.body}"
    Foobar.last.should_not be_nil, "Last Foobar was nil"
    Foobar.last.foo_id.should eq(foo.id), "Expected created Foobar to have foo_id #{foo.id.inspect} but was #{Foobar.last.foo_id.inspect}"
    response.body.should eq("{\"check\":\"foobars-create: #{Foobar.last.id}\"}")
  end

  it 'create does not accept non-whitelisted params' do
    begin
      bar = Bar.create
      json_create foobar: {bar_id: bar.id}
      fail 'Expected ActionController::UnpermittedParameters to be raised for non-whitelisted param'
    rescue ActionController::UnpermittedParameters
      Foobar.where(bar_id: bar.id).should be_empty, "should not have created with non-whitelisted param"
    end
  end

  it 'create does not create when cancan disallows user' do
    FoobarsController.test_role = 'nobody'

    start_count = Foobar.count
    begin
      json_create
      fail "cancan should not allow put" if response.status < 400
    rescue
    end
    Foobar.count.should eq(start_count), "should not have created new record when CanCan disallows user"
  end

  it 'update allowed for accepted params' do
    foobar = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
    foo_id = Foo.first.id
    json_update foobar: {Foobar.primary_key => foobar.id, foo_id: foo_id}
    response.status.should eq(204), "update failed (got #{response.status}): #{response.body}"
    assert_match '', response.body
    Foobar.find(foobar.id).foo_id.should eq(foo_id), "should have updated param"
  end

  it 'update does not accept non-whitelisted params' do
    orig_bar_id = "k#{SecureRandom.urlsafe_base64}"
    foobar = Foobar.create(bar_id: orig_bar_id)
    bar_id = Bar.first.id
    begin
      json_update foobar: {Foobar.primary_key => foobar.id, bar_id: bar_id}
      fail 'should have raised for non-whitelisted param'
    rescue ::ActionController::UnpermittedParameters
    end
    Foobar.find(foobar.id).bar_id.should eq(orig_bar_id), "should not have updated with non-whitelisted param. expected #{orig_bar_id} but bar_id was #{Foobar.find(foobar.id).bar_id}"
  end

  it 'update does not accept whitelisted params when cancan disallows user' do
    FoobarsController.test_role = 'nobody'
    foobar = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
    foo_id = Foo.first.id
    begin
      json_update foobar: {Foobar.primary_key => foobar.id, foo_id: foo_id}
      fail "cancan should not allow put" if response.status < 400
    rescue
    end
    Foobar.find(foobar.id).foo_id.should eq(foobar.foo_id), "should not have updated with whitelisted param when cancan disallows user"
  end

  it 'update fails with HTTP 404 for missing record' do
    begin
      json_update foobar: {id: '9999999', foo_id: ''}
      fail "should have raised error"
    rescue
      Foobar.where(id: '9999999').should be_empty, "should not have created record"
    end
  end

  it 'destroy allowed for accepted id' do
    foobar = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
    json_destroy id: foobar
    assert_match '', response.body
    response.status.should eq(200), "destroy failed (got #{response.status}): #{response.body}"
  end

  it 'destroy is idempotent/should not fail for missing record' do
    json_destroy id: '9999999'
    assert_match '', response.body
    response.status.should eq(200), "destroy failed (got #{response.status}): #{response.body}"
  end

  it 'destroy should fail with error if subclass of StandardError' do
    begin
      foobar = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      # expect this to make destroy fail and reset in after hook
      $error_to_raise_on_next_save_or_destroy_only = SomeSubtypeOfStandardError.new("some type of standard error")
      json_destroy id: foobar
      fail "should have raised error"
    rescue
    end
  end
end
