# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "restful_json/version" 

Gem::Specification.new do |s|
  s.name        = 'restful_json'
  s.version     = RestfulJson::VERSION
  s.authors     = ['Gary S. Weaver']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/garysweaver/restful_json'
  s.summary     = %q{RESTful JSON controllers using Rails 3.x.}
  s.description = %q{Provides RESTful JSON controller implementations that let you either extend the Controller and just define the model name as part of your controller name per convention or can extend from a BaseController and define the model name via a method.}
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  s.add_dependency 'rails-api'
  s.add_dependency 'active_model_serializers'
  s.add_dependency 'actionpack'
  s.add_dependency 'activerecord'
  s.add_dependency 'cancan'
  s.add_dependency 'convenient-actionpack'
  s.add_dependency 'strong_parameters'
end
