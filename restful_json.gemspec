# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "restful_json/version" 

Gem::Specification.new do |s|
  s.name        = 'restful_json'
  s.version     = RestfulJson::VERSION
  s.authors     = ['Gary S. Weaver', 'Tommy Odom']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/rubyservices/restful_json'
  s.summary     = %q{RESTful JSON controllers using Rails 3.1+, Rails 4+.}
  s.description = %q{Develop declarative, featureful JSON RESTful-ish service controllers to use with modern Javascript MVC frameworks like AngularJS, Ember, etc. with much less code.}
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  #s.add_runtime_dependency 'actionpack', '>= 3.1.0'
  #s.add_runtime_dependency 'activerecord', '>= 3.1.0'
  s.add_development_dependency 'bundler', [">= 1.2.2"]
  s.add_development_dependency 'appraisal' 
end
