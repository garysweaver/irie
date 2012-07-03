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

You would do this in app/controllers/foobar_controller.rb:

    class FoobarController < RestfulJson::Controller
    end

Then in config/routes.rb, you would add:

    resources :foobar

That's it. Now you can serve up some Javascript in one of your views that hits the RESTful services that have been defined.

### The JSON Services

The first part is just basic stuff from a resourceful routes in Rails 3, but it might help.

You'd start the server:

    rails s

You could then list all Foobars with a GET to:

    http://localhost:3000/foobar.json

To find out what the JSON to use as the 'foobar' parameter value, you could create one first in Rails console and then get that or call to_json on it in the console.

Get a specific foobar using a GET to:

    http://localhost:3000/foobar/object_id.json

POST the JSON of a new Foobar as request parameter 'foobar' to create one:

    http://localhost:3000/foobar/new.json

Update a Foobar with a PUT call to:

    http://localhost:3000/foobar/object_id.json

And destroy it with a DELETE call to:

    http://localhost:3000/foobar/object_id.json

You might also look at the output of 'rake routes' to see the paths for /foobar and then construct URLs to test it:

    rake routes

#### CORS

If you have javascript/etc. code in the client that is running under a different host or port than Rails server, then you are cross-origin/cross-domain and we handle this with [CORS][cors].

By default CORS is disabled, so to enable it you can either set the environment variable RESTFUL_JSON_CORS_GLOBALLY_ENABLED, or in config/environment.rb or for a specific environment like config/environments/development.rb you can add the following global variable:

    $restful_json_cors_globally_enabled = true

By default, we make CORS just allow everything, so the whole cross-origin/cross-domain thing goes away and you can get to developing locally with your Javascript app that isn't even being served by Rails.

##### Customizing CORS

So, if you enabled CORS, then CORS starts with a [preflight request][preflight_request] from the client (the browser), to which we respond with a response. You can customize the values of headers returned in the :cors_preflight_headers option. Then for all other requests to the controller, you can specify headers to be returned in the :cors_access_control_headers option.

Here's an example of customizing both:

    class MyModelController < RestfulJson::Controller
      def initialize
        restful_json_options({
          cors_preflight_headers: {
            'Access-Control-Allow-Origin':  '*',
            'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
            'Access-Control-Allow-Headers': 'X-Requested-With, X-Prototype-Version',
            'Access-Control-Max-Age': '1728000'
          },
          cors_access_control_headers: {
            'Access-Control-Allow-Origin':  '*',
            'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
            'Access-Control-Max-Age': '1728000'
          }
        })
        super
      end
    end

### Future

Filter

#### Using a Different Model

I wanted to just do it in the class vs. initialize so it would look cleaner, but I think this makes things overall a lot clearer considering that that RestfulJson::Controller also looks at its name to determine model in its initializer:

    # Note that we're using BaseController here. It doesn't try to guess the model class, etc.
    class MyModelController < RestfulJson::BaseController
      def initialize
        restful_json_model TestModel
        
        # note: If you were to inherit from RestfulJson::Controller, then super would look
        #       at the classname, etc. to find the model class. Order doesn't matter here.
        super
      end
    end

### License

Copyright (c) 2012 Gary S. Weaver, released under the [MIT license][lic].

[ember_data_example]: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
[angular]: http://angularjs.org/
[cors]: http://enable-cors.org/
[preflight_request]: http://www.w3.org/TR/cors/#resource-preflight-requests
[lic]: http://github.com/garysweaver/activerecord-attribute-override/blob/master/LICENSE
