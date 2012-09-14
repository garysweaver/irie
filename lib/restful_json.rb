require 'restful_json/version'
require 'restful_json/roar/autorepresenter'
require 'restful_json/roar/collectionless_autorepresenter'
require 'restful_json/controller'
require 'restful_json/options'
require 'restful_json/model'
require 'restful_json/controller'
require 'restful_json/railtie' if defined?(Rails)

puts "RestfulJson #{::RestfulJson::VERSION}" if ::RestfulJson::Options.debugging?
