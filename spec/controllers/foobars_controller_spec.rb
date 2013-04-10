require 'rails'
require 'spec_helper'

describe FoobarsController do

  before(:each) do
    @orig = RestfulJson.avoid_respond_with
    RestfulJson.avoid_respond_with = false
  end

  after(:each) do
    RestfulJson.avoid_respond_with = @orig
  end

  describe "GET index" do
    it 'returns foobars in correct order' do
      Foobar.delete_all
      expected = []
      10.times do |c|
        expected << Foobar.create(foo_id: c, foo_date: Time.new(2012 - c), bar_date: Time.new(2012 + c))
      end
      get :index, :format => :json
      assigns(:foobars).should eq(expected.reverse)
    end
  end

   describe "POST create" do
    it 'allowed for accepted params' do
      FoobarsController.test_role = 'admin'
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
      FoobarsController.test_role = 'admin'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      bar_id = SecureRandom.urlsafe_base64
      post :create, bar_id: bar_id, format: :json
      response.status.should eq(201), "create failed (got #{response.status}): #{response.body}"
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
      FoobarsController.test_role = 'admin'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      foo_id = '1'
      put :update, id: b.id, foo_id: foo_id, format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
      Foobar.where(foo_id: foo_id).should_not be_empty, "should have updated param"
    end

    it 'does not accept non-whitelisted params' do
      FoobarsController.test_role = 'admin'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(bar_id: SecureRandom.urlsafe_base64)
      bar_id = '1'
      put :update, id: b.id, bar_id: bar_id, format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "update failed (got #{response.status}): #{response.body}"
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
        put :update, id: b.id, foo_id: foo_id, format: :json
        fail "cancan should not allow put" if response.status < 400
      rescue
      end
      Foobar.where(foo_id: foo_id).should be_empty, "should not have updated with whitelisted param when cancan disallows user"
    end

    it 'fails with HTTP 404 for missing record' do
      FoobarsController.test_role = 'admin'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      put :update, id: '9999999', foo_id: '', format: :json
      response.status.should eq(404), "update should have failed with not found (got #{response.status}): #{response.body}"
      Foobar.where(id: '9999999').should be_empty, "should not have created record"
    end

    #TODO: implement ability in permitters to return 400 Bad Request like strong_parameters, if invalid params provided. currently is just ignored
    #it 'fails for rejected params' do
    #  Foobar.delete_all
    #  # won't wrap in test without this per https://github.com/rails/rails/issues/6633
    #  @request.env['CONTENT_TYPE'] = 'application/json'
    #  b = Foobar.create(bar_id: SecureRandom.urlsafe_base64)
    #  put :update, id: b.id, bar_id: '1', format: :json
    #  response.status.should eq(400), "update should have failed for unaccepted param (got #{response.status}): #{response.body}"
    #end
  end

  describe "DELETE destroy" do
    it 'allowed for accepted id' do
      FoobarsController.test_role = 'admin'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      b = Foobar.create(foo_id: SecureRandom.urlsafe_base64)
      delete :destroy, id: b, format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "destroy failed (got #{response.status}): #{response.body}"
    end

    it 'should not fail with HTTP 404 for missing record' do
      FoobarsController.test_role = 'admin'
      Foobar.delete_all
      # won't wrap in test without this per https://github.com/rails/rails/issues/6633
      @request.env['CONTENT_TYPE'] = 'application/json'
      delete :destroy, id: '9999999', format: :json
      expected_code = Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 ? 200 : 204
      response.status.should eq(expected_code), "destroy failed (got #{response.status}): #{response.body}"
    end
  end
end
