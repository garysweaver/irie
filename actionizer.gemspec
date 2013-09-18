# -*- encoding: utf-8 -*-  
$:.push File.expand_path("../lib", __FILE__)  
require "actionizer/version" 

Gem::Specification.new do |s|
  s.name        = 'actionizer'
  s.version     = Actionizer::VERSION
  s.authors     = ['Gary S. Weaver', 'Tommy Odom']
  s.email       = ['garysweaver@gmail.com']
  s.homepage    = 'https://github.com/FineLinePrototyping/actionizer'
  s.summary     = %q{Easy, flexible, modular Rails controller actions.}
  s.description = %q{Write controllers with a conventional URL-based query syntax, where you control what can be done the way you'd write an ActiveRecord model, with a mix of declarative and imperative code. HTML, JSON, etc. supported.}
  s.files = Dir['lib/**/*'] + ['Rakefile', 'README.md']
  s.license = 'MIT'
  s.add_runtime_dependency 'actionpack', '>= 4.0.0'
  s.add_runtime_dependency 'activerecord', '>= 4.0.0'
  s.add_runtime_dependency 'activesupport', '>= 4.0.0'
end
