require 'restful_json/version'
require 'restful_json/config'
require 'twinturbo/application_permitter'
require 'twinturbo/controller'
require 'restful_json/model'
require 'restful_json/controller'
require 'restful_json/railtie' if defined?(Rails)

puts "RestfulJson #{RestfulJson::VERSION}" if RestfulJson.debug?
