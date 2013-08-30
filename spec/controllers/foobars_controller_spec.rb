require 'rails'
require 'spec_helper'

class SomeSubtypeOfStandardError < StandardError
end

describe FoobarsController do
  render_views

  before(:each) do
    FoobarsController.test_role = 'admin'
    10.times do |c|
      Foo.where(:id => c, :code => "123#{c}").first_or_create
      Bar.where(:id => c, :code => "abc#{c}").first_or_create
    end
  end

  describe "GET index" do
    it 'returns foobars in correct order' do
      Foobar.delete_all
      expected = []
      
      10.times do |c|
        expected << Foobar.create(foo: Foo.where(id: c).first)
      end
      get :index, format: :json
      assigns(:foobars).should eq(expected.reverse)
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should eq("{\"check\":\"foobars-index: size=3, ids=borscht 2,borscht 5,borscht 8}\"")
    end
  end

  describe "GET show" do
    it 'assigns foobar' do
      Foobar.delete_all
      b = Foobar.create(foo: Foo.where(id: 1).first)
      get :show, Foobar.primary_key => b.id, format: :json
      assigns(:foobar).is_a?(Foobar).should be
      response.status.should eq(200), "show failed (got #{response.status}): #{response.body}"
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should eq("{\"check\":\"foobars-show: #{b.id}\"}")
    end

    it 'fails for bad id' do
      begin
        Foobar.delete_all
        get :show, id: '9999999', format: :json
        fail('should have raised error')
      rescue => e
        e.message.should include('ound')
      end
    end
  end

  describe "GET new" do
    it 'assigns foobar' do
      Foobar.delete_all
      get :new, format: :json
      assigns(:foobar).is_a?(Foobar).should be
      response.status.should eq(200), "new failed (got #{response.status}): #{response.body}"
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should eq("{\"check\":\"foobars-new: \"}")
    end
  end

  describe "GET edit" do
    it 'assigns foobar' do
      Foobar.delete_all
      b = Foobar.create(foo: Foo.where(id: 1).first)
      get :edit, Foobar.primary_key => b.id, format: :json
      assigns(:foobar).is_a?(Foobar).should be
      assigns(:foobar).foo_id.should eq(1)
    end

    it 'fails for bad id' do
      begin
        Foobar.delete_all
        get :edit, id: '9999999', format: :json
        fail "should have raised error"
      rescue
        assigns(:foobar).should be_nil
      end
    end
  end

   describe "POST create" do
    it 'allowed for accepted params' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      before_count = Foobar.count
      #autolog do
        post :create, foobar: {foo: Foo.where(id: 1).first.to_json}, format: :json
      #end
      response.status.should eq(201), "create failed (got #{response.status}): #{response.body}"
      Foobar.count.should eq(before_count + 1)
      @response.body.should eq("{\"check\": \"foobars-create\": 1}")
    end

    it 'does not accept non-whitelisted params' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      post :create, foobar: {bar: Bar.where(id: 1).first}, format: :json
      # should pass but just not let this be updated
      response.status.should eq(201), "create failed (got #{response.status}): #{response.body}"
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should eq("{\"check\": \"foobars-create\": 1}")
      Foobar.where(bar_id: 1).should be_empty, "should not have created with non-whitelisted param"
    end

    it 'does not accept whitelisted params when cancan disallows user' do
      FoobarsController.test_role = 'nobody'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      foo_id = SecureRandom.urlsafe_base64
      begin
        put :create, foo: Foo.where(id: 1).first, format: :json
        fail "cancan should not allow put" if response.status < 400
      rescue
      end
      assert_match '', @response.body
      Foobar.where(foo_id: 1).should be_empty, "should not have updated with whitelisted param when cancan disallows user"
    end

    it "fails for invalid json" do
      begin
        @request.env['RAW_POST_DATA'] = "{this is invalid json'}"
        post :create, format: :json
        fail "should have raised error"
      rescue => e
        response.status.should eq(500), "expected response status 500 (#{response.status}): #{response.body}"
      ensure
        @request.env.delete('RAW_POST_DATA')
      end
    end

    #TODO: implement ability in permitters to return 400 Bad Request like strong_parameters, if invalid params provided. currently is just ignored
    #it 'fails for rejected params' do
    #  Foobar.delete_all
    #  # won't wrap in test without this per https://github.com/rails/rails/issues/6633
    #  @request.env['CONTENT_TYPE'] = 'application/json'
    #  post :create, bar_id: SecureRandom.urlsafe_base64, format: :json
    #  response.status.should eq(400), "create should have failed for unaccepted param (got #{response.status}): #{response.body}"
    #end
  end

  describe "PUT update" do
    it 'allowed for accepted params' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      foo_id = '1'
      put :update, Foobar.primary_key => b.id, foo_id: foo_id, format: :json
      response.status.should eq(204), "update failed (got #{response.status}): #{response.body}"
      assert_match '', @response.body
      Foobar.where(foo_id: foo_id).should_not be_empty, "should have updated param"
    end

    it 'does not accept non-whitelisted params' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(bar_id: SecureRandom.urlsafe_base64)
      bar_id = '1'
      put :update, Foobar.primary_key => b.id, bar_id: bar_id, format: :json
      response.status.should eq(204), "update failed (got #{response.status}): #{response.body}"
      assert_match '', @response.body
      Foobar.where(bar_id: bar_id).should be_empty, "should not have updated with non-whitelisted param"
    end

    it 'does not accept whitelisted params when cancan disallows user' do
      FoobarsController.test_role = 'nobody'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      foo_id = '1'
      begin
        put :update, Foobar.primary_key => b.id, foo_id: foo_id, format: :json
        fail "cancan should not allow put" if response.status < 400
      rescue
      end
      Foobar.where(foo_id: foo_id).should be_empty, "should not have updated with whitelisted param when cancan disallows user"
    end

    it 'fails with HTTP 404 for missing record' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      put :update, id: '9999999', foo_id: '', format: :json
      response.status.should eq(404), "update should have failed with not found (got #{response.status}): #{response.body}"
      assert_match ' ', @response.body
      Foobar.where(id: '9999999').should be_empty, "should not have created record"
    end

    #TODO: implement ability in permitters to return 400 Bad Request like strong_parameters, if invalid params provided. currently is just ignored
    #it 'fails for rejected params' do
    #  Foobar.delete_all
    #  # won't wrap in test without this per https://github.com/rails/rails/issues/6633
    #  @request.env['CONTENT_TYPE'] = 'application/json'
    #  b = Foobar.create(bar_id: SecureRandom.urlsafe_base64)
    #  put :update, Foobar.primary_key => b.id, bar_id: '1', format: :json
    #  response.status.should eq(400), "update should have failed for unaccepted param (got #{response.status}): #{response.body}"
    #end
  end

  describe "DELETE destroy" do
    it 'allowed for accepted id' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      delete :destroy, id: b, format: :json
      assert_match '', @response.body
      response.status.should eq(200), "destroy failed (got #{response.status}): #{response.body}"
    end

    it 'should not fail with HTTP 404 for missing record' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      delete :destroy, id: '9999999', format: :json
      assert_match '', @response.body
      response.status.should eq(200), "destroy failed (got #{response.status}): #{response.body}"
    end

    it 'should fail with error if subclass of StandardError' do
      begin
        Foobar.delete_all
        # won't wrap in test without this per https://github.com/rails/rails/issues/6633
        @request.env['CONTENT_TYPE'] = 'application/json'
        b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
        # expect this to make destroy fail and reset in after hook
        $error_to_raise_on_next_save_or_destroy_only = SomeSubtypeOfStandardError.new("some type of standard error")
        delete :destroy, id: b, format: :json
        fail "should have raised error"
      rescue
      end
    end
  end
end
