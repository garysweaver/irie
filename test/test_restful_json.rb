require 'test/unit'
require 'action_controller'
require 'active_support/inflector'

# simulate Rails controller having already been loaded
class ApplicationController < ActionController::Base
end

require 'restful_json'

# simular ActiveRecord::Base for testing with models
module ActiveRecord
  class Base
  end
end

# Test models

class Foobar
end

class TestModel < ActiveRecord::Base
end

class TestAnotherModel < ActiveRecord::Base
end

# Test controllers

# attempts to define but not activerecord model.
class FoobarService < RestfulJson::Controller
end

# should be defined.
class FoobarDefinedService < RestfulJson::Controller
  restful_json_model TestModel
end

# should attempt to define because of name, and fail because not an AR model.
class FoobarController < RestfulJson::Controller
end

# should be defined because of name.
class TestModelController < RestfulJson::Controller
end

# should be defined.
class TestAnotherModelController < RestfulJson::BaseController
  restful_json_model TestModel
end

class TestRestfulJson < Test::Unit::TestCase
  
  # test what shouldn't work

  def test_nonautoconfigured_nonstandard_controller_name_is_not_configured
     test = FoobarService.new
     assert !test.respond_to?(:index)
  end

  def test_autoconfigured_controller_with_non_model_in_name_not_configured
     test = FoobarController.new
     assert !test.respond_to?(:index)
  end

  # test what should work

  def test_configured_controller_with_nonstandard_name_is_configured
     test = FoobarDefinedService.new
     assert test.respond_to?(:index)
  end

  def test_autoconfigured_controller_with_model_in_name_is_configured
     test = TestModelController.new
     assert test.respond_to?(:index)
  end

  # both

  def test_can_be_manually_configured
    test = TestAnotherModelController.new
    assert test.respond_to?(:index)
  end

end