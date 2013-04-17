require 'rails'
require 'spec_helper'

#[:json].each do |req_format|
#  {PostsController => Post, MyPostsController => MyPost}.each do |controller_class, model_class|
#
#    describe controller_class do
#
#      before(:each) do
#        @plural_model_class_sym = model_class.name.underscore.pluralize.to_sym
#        @singular_model_class_sym = model_class.name.underscore.to_sym
#        @value = model_class.create(name: 'MyString', title: 'MyString', content: 'MyText')
#      end
#
#      after(:each) do
#        model_class.delete_all
#      end
#
#      it "should get index #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#        get :index, format: req_format
#        @response.status.should eq(200)
#        assigns(@plural_model_class_sym).should_not be_nil, "#{controller_class.name} did not assign #{@plural_model_class_sym}"
#      end
#
#      if req_format == :html
#        it "should get new #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#          get :new, format: req_format
#          @response.status.should eq(200), "#{controller_class.name} returned #{@response.status} when expected 200"
#        end
#      end
#
#      it "should create post #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#        initial_count = model_class.count
#        @request.env['CONTENT_TYPE'] = 'application/json' if req_format == :json
#        post :create, @singular_model_class_sym => { content: @value.content, name: @value.name, title: @value.title }, format: req_format
#        model_class.count.should_not eq(initial_count), "#{model_class.name}.count should not have been #{initial_count}"
#        if req_format == :html
#          assert_redirected_to post_path(assigns(@singular_model_class_sym)), "was not redirected to #{post_path(assigns(@singular_model_class_sym))}"
#        end
#      end
#
#      it "should show post #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#        get :show, id: @value, format: req_format
#        response.status.should eq(200), "#{controller_class.name} returned #{@response.status} when expected 200"
#      end
#
#      if req_format == :html
#        it "should get edit #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#          get :edit, id: @value, format: req_format
#          response.status.should eq(200), "#{controller_class.name} returned #{@response.status} when expected 200"
#        end
#      end
#
#      it "should update post #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#        @request.env['CONTENT_TYPE'] = 'application/json' if req_format == :json
#        patch :update, id: @value, @singular_model_class_sym => { content: @value.content, name: @value.name, title: @value.title }, format: req_format
#        if req_format == :html
#          assert_redirected_to post_path(assigns(@singular_model_class_sym)), "was not redirected to #{post_path(assigns(@singular_model_class_sym))}"
#        end
#      end
#
#      it "should destroy post #{model_class == Post ? 'using default Rails scaffold\'s controller' : 'using restful_json controller'}" do
#        initial_count = model_class.count
#        delete :destroy, id: @value, format: req_format
#        model_class.count.should eq(initial_count - 1), "#{model_class.name}.count was #{model_class.count} instead of #{initial_count - 1}"
#        if req_format == :html
#          assert_redirected_to posts_path, "was not redirected to #{posts_path}"
#        end
#      end
#    end
#  end
#end#