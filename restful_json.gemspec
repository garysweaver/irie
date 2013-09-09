# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "restful_json/version" 

Gem::Specification.new do |s|
  s.name        = 'restful_json'
  s.version     = RestfulJson::VERSION
  s.authors     = ['Gary S. Weaver', 'Tommy Odom']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/FineLinePrototyping/restful_json'
  s.summary     = %q{Easy, powerful, flexible Rails JSON service controllers.}
  s.description = %q{Develop featureful JSON service controllers for use with modern Javascript MVC frameworks like AngularJS, Ember, etc. with much less code.}
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  s.add_runtime_dependency 'actionpack', '>= 4.0.0'
  s.add_runtime_dependency 'activerecord', '>= 4.0.0'
  s.add_runtime_dependency 'activesupport', '>= 4.0.0'
end
