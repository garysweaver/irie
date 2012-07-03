require "test/unit"
require "action_controller"
require "active_support/inflector"
require "restful_json"

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

module FirstModule
  module SecondModule
    class NamespacedModel < ActiveRecord::Base
    end
  end
end

# Test controllers

# attempts to define but not activerecord model.
class FoobarService < RestfulJson::Controller
end

# should be defined.
class FoobarDefinedService < RestfulJson::Controller
  def initialize; super; restful_json_model TestModel; end
end

# should attempt to define because of name, and fail because not an AR model.
class FoobarController < RestfulJson::Controller
end

# should be defined because of name.
class TestModelController < RestfulJson::Controller
end

# should be defined.
class TestAnotherModelController < RestfulJson::BaseController
  def initialize; super; restful_json_model TestModel; end
end

# should be defined.
class FoobarDefinedService < RestfulJson::Controller
  def initialize; super; restful_json_model TestModel; end
end

# should be defined because finds model in default namespace.
module FirstModule
  module SecondModule
    class TestModelController < RestfulJson::Controller
    end
  end
end

# should be defined because finds model in same namespace.
module FirstModule
  module SecondModule
    class NamespacedModelController < RestfulJson::Controller
    end
  end
end

class TestRestfulJson < Test::Unit::TestCase
  
  # test what shouldn't work

  def test_nonautoconfigured_nonstandard_controller_name_is_not_configured
     test = FoobarService.new
     puts "should not have foobar etc in it #{test.instance_variable_names}"
     assert !test.instance_variable_names.include?("@foobarservice"), "@foobarservice shouldn't be in list of instance_variable_names: #{test.instance_variable_names}"
     assert !test.instance_variable_names.include?("@foobar_service"), "@foobar_service shouldn't be in list of instance_variable_names: #{test.instance_variable_names}"
  end

  def test_autoconfigured_controller_with_non_model_in_name_not_configured
     test = FoobarController.new
     assert !test.instance_variable_names.include?("@foobar"), "@foobar shouldn't be in list of instance_variable_names"
     assert !test.instance_variable_names.include?("@foobarcontroller"), "@foobarcontroller shouldn't be in list of instance_variable_names: #{test.instance_variable_names}"
     assert !test.instance_variable_names.include?("@foobar_controller"), "@foobar_controller shouldn't be in list of instance_variable_names: #{test.instance_variable_names}"
  end

  # test what should work

  def test_configured_controller_with_nonstandard_name_is_configured
     test = FoobarDefinedService.new
     assert test.instance_variable_names.include?("@test_model"), "@test_model should be in list of instance_variable_names: #{test.instance_variable_names}"
  end

  def test_autoconfigured_controller_with_model_in_name_is_configured
     test = TestModelController.new
     assert test.instance_variable_names.include?("@test_model"), "@test_model should be in list of instance_variable_names: #{test.instance_variable_names}"
  end

  def test_namespaced_autoconfigured_controller_with_no_namespace_model_in_name_is_configured
     test = FirstModule::SecondModule::TestModelController.new
     assert test.instance_variable_names.include?("@test_model"), "@test_model should be in list of instance_variable_names: #{test.instance_variable_names}"
  end

  def test_namespaced_autoconfigured_controller_with_namespaced_model_in_name_is_configured
     test = FirstModule::SecondModule::NamespacedModelController.new
     assert test.instance_variable_names.include?("@namespaced_model"), "@namespaced_model should be in list of instance_variable_names: #{test.instance_variable_names}"
  end

  # both

  def test_can_be_manually_configured
    test = TestAnotherModelController.new
    assert test.instance_variable_names.include?("@test_model"), "@test_model should be in list of instance_variable_names: #{test.instance_variable_names}"
  end

end