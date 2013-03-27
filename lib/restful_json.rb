require 'restful_json/version'
require 'restful_json/config'
#if defined?(::Rails)
  if defined?(::ActionController::StrongParameters) && defined?(::CanCan::ModelAdditions)
    require 'application_permitter'
    require 'twinturbo/controller'
  end
  require 'restful_json/model'
  require 'restful_json/controller'
  require 'restful_json/railtie'
#end
