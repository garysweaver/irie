RESTful JSON for Rails 3.x
=====

A gem that loads a class called RestfulJson::Controller that extends your ApplicationController that you can use to easily make controllers in Rails 3.x that dynamically add RESTful JSON methods to your controllers to reduce code clutter and just focus on the javascript (or whatever makes you happy these days) frontend that interacts with it.

The intent is to allow a simple way to use Rails as a RESTful JSON service backend for a javascript-based front-end. Some believe that you should have the boilerplate code all over your controllers, which you may decide is better for you, but using restful-json will save you some code and opts for a simpler implementation.

The controller implementation borrows heavily from Dan Gebhardt's example in [ember_data_example][ember_data_example] even though it is just a generic RESTful JSON service implementation that is Javascript-friendly and isn't meant to be ember-specific- in fact, I'm testing it with [angular.js][angular].

### Setup

In your Rails 3+ project, add this to your Gemfile:

    gem 'restful_json', :git => 'git://github.com/garysweaver/restful_json.git'

Then run:

    bundle install

### Usage

Just have your controller extend RestfulJson::Controller. If your controller is named MyModelNameController then it will assume the model name is MyModelName. If your controller is named SomeModule::MyModelNameController then it will first try the model name as SomeModule::MyModelName and if that isn't a valid ActiveRecord model it will also try MyModelName.

So if you had an existing model app/models/foobar.rb:

    class Foobar < ActiveRecord::Base
    end

If you have a Rails 3 controller and a Foobar model, you'd just extend our automatically configuring controller and it would automatically provide:

    class FoobarController < RestfulJson::Controller
    end

Then in config/routes.rb, add:

    resources :foobar

That's it. Now you can serve up some Javascript in one of your views that hits the RESTful services that have been defined.

### License

Copyright (c) 2012 Gary S. Weaver, released under the [MIT license][lic].

[ember_data_example]: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
[angular]: http://angularjs.org/
[lic]: http://github.com/garysweaver/activerecord-attribute-override/blob/master/LICENSE
