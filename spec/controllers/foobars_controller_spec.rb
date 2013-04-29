require 'rails'
require 'spec_helper'

class SomeSubtypeOfStandardError < StandardError
end

describe FoobarsController do

  before(:each) do
    @orig = RestfulJson.avoid_respond_with
    RestfulJson.avoid_respond_with = false
    FoobarsController.test_role = 'admin'
  end

  after(:each) do
    RestfulJson.avoid_respond_with = @orig
  end

  describe "GET index" do
    it 'returns foobars in correct order' do
      Foobar.delete_all
      expected = []
      10.times do |c|
        expected << Foobar.create(foo_id: c)
      end
      get :index, :format => :json
      assigns(:foobars).should eq(expected.reverse)
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should be_json_eql("{\"foobars\":[{\"id\":\"x\",\"foo_id\":\"9\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"8\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"7\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"6\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"5\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"4\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"3\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"2\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"1\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null},{\"id\":\"x\",\"foo_id\":\"0\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null}]}")
    end
  end

  describe "GET show" do
    it 'assigns foobar' do
      Foobar.delete_all
      b = Foobar.create(foo_id: '1')
      get :show, Foobar.primary_key => b.id, :format => :json
      assigns(:foobar).is_a?(Foobar).should be
      response.status.should eq(200), "show failed (got #{response.status}): #{response.body}"
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should be_json_eql("{\"foobar\":{\"id\":#{b.id},\"foo_id\":\"1\",\"bar_id\":null,\"foo_date\":null,\"bar_date\":null}}")
    end

    it 'fails for bad id' do
      Foobar.delete_all
      get :show, id: '9999999', :format => :json
      assigns(:foobar).should be_nil
      response.status.should eq(404), "show should have failed (got #{response.status}): #{response.body}"
    end
  end

  describe "GET new" do
    it 'assigns foobar' do
      Foobar.delete_all
      get :new, :format => :json
      assigns(:foobar).is_a?(Foobar).should be
      response.status.should eq(200), "new failed (got #{response.status}): #{response.body}"
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should be_json_eql('{"foobar":{"id":null,"foo_id":null,"bar_id":null,"foo_date":null,"bar_date":null}}')
    end
  end

  describe "GET edit" do
    it 'assigns foobar' do
      Foobar.delete_all
      b = Foobar.create(foo_id: '1')
      get :edit, Foobar.primary_key => b.id, :format => :json
      assigns(:foobar).is_a?(Foobar).should be
      assigns(:foobar).foo_id.should eq('1')
    end

    it 'fails for bad id' do
      begin
        Foobar.delete_all
        get :edit, id: '9999999', :format => :json
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
      foo_id = SecureRandom.urlsafe_base64
      #autolog do
        post :create, foo_id: foo_id, format: :json
      #end
      response.status.should eq(201), "create failed (got #{response.status}): #{response.body}"
      Foobar.where(foo_id: foo_id).should_not be_empty, "should have created param"
    end

    it 'does not accept non-whitelisted params' do
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      bar_id = SecureRandom.urlsafe_base64
      post :create, bar_id: bar_id, format: :json
      response.status.should eq(201), "create failed (got #{response.status}): #{response.body}"
      # note: ids, created_at, updated_at and order of keys are ignored- see https://github.com/collectiveidea/json_spec
      @response.body.should be_json_eql("{\"foobar\":{\"id\":\"x\",\"foo_id\":null,\"bar_id\":null,\"foo_date\":null,\"bar_date\":null}}")
      Foobar.where(bar_id: bar_id).should be_empty, "should not have created with non-whitelisted param"
    end

    it 'does not accept whitelisted params when cancan disallows user' do
      FoobarsController.test_role = 'nobody'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      foo_id = SecureRandom.urlsafe_base64
      begin
        put :create, foo_id: foo_id, format: :json
        fail "cancan should not allow put" if response.status < 400
      rescue
      end
      assert_match '', @response.body
      Foobar.where(foo_id: foo_id).should be_empty, "should not have updated with whitelisted param when cancan disallows user"
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
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
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
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
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
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      # expect this to make destroy fail and reset in after hook
      $error_to_raise_on_next_save_or_destroy_only = SomeSubtypeOfStandardError.new("some type of standard error")
      delete :destroy, id: b, format: :json
      # this is a weak check
      @response.body['error'].should_not be_nil
      @response.body['some type of standard error'].should_not be_nil
      response.status.should eq(500), "destroy should have failed with 500 (got #{response.status}): #{response.body}"
    end

    it 'should not fail with i18n message if has 500 error with missing optional i18n key' do
      orig_handlers = RestfulJson.rescue_handlers
      RestfulJson.rescue_handlers = {status: :internal_server_error, i18n_key: 'this_is_an_missing_and_invalid_i18n_key'.freeze}
      begin
        Foobar.delete_all
        # won't wrap in test without this per https://github.com/rails/rails/issues/6633
        @request.env['CONTENT_TYPE'] = 'application/json'
        b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
        # expect this to make destroy fail and reset in after hook
        $error_to_raise_on_next_save_or_destroy_only = SomeSubtypeOfStandardError.new("some type of standard error")
        delete :destroy, id: b, format: :json
        # this is a weak check
        @response.body['error'].should_not be_nil
        @response.body['some type of standard error'].should_not be_nil
        # we don't want error to be "translation missing: en.api.this_is_an_missing_and_invalid_i18n_key" or anything similar
        @response.body['ranslation'].should be_nil, "assuming got a translation missing error because 'ranslation' was in the response body string"
        @response.body['this_is_an_missing_and_invalid_i18n_key'].should be_nil, "assuming got a translation missing error because 'this_is_an_missing_and_invalid_i18n_key' was in the response body string"
        # but it should still fail
        response.status.should eq(500), "destroy should have failed with 500 (got #{response.status}): #{response.body}"
      ensure
        # we're not expecting an exception, but want to reset app-wide config back just in case
        RestfulJson.rescue_handlers = orig_handlers
      end
    end
  end
end
