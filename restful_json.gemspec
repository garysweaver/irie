# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "restful_json/version" 

Gem::Specification.new do |s|
  s.name        = 'restful_json'
  s.version     = ::RestfulJson::VERSION
  s.authors     = ['Gary S. Weaver']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/garysweaver/restful_json'
  s.summary     = %q{RESTful JSON controllers using Rails 3.x.}
  s.description = %q{Provides RESTful JSON controller implementations that let you either extend the Controller and just define the model name as part of your controller name per convention or can extend from a BaseController and define the model name via a method.}
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  s.add_dependency 'activerecord', '>= 3.1'
  s.add_dependency 'roar-rails', '~> 0.0.10'
  # this should be a dependency, not a runtime dependency, of roar-rails
  s.add_dependency "roar", "~> 0.10"
  s.add_dependency "representable", "~> 1.2.2"
  s.add_dependency "virtus", "~> 0.5.0"
end
