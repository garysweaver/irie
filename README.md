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

    class FoobarController < ApplicationController
      acts_as_restful_json
    end

Then in config/routes.rb, you would add:

    resources :foobar

That's it. Now you can serve up some Javascript in one of your views that hits the RESTful services that have been defined.

### The JSON Services

#### Basics

The first part is just basic stuff from a resourceful routes in Rails 3, but it might help.

You'd start the server:

    rails s

You could then list all Foobars with a GET to what equates to the "list" command:

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

#### Filtering

Attributes marked as accessible in the model can be queried by specifying the value of the request parameter as the attribute in the list query.

For example, if Foobar were to have an ActiveRecord attribute called "color" (because the backing database table has a column named color), you could do:

    http://localhost:3000/foobar.json?color=blue

#### Changing JSON format and Including Association Data

#### Customizing ActiveRecord Queries/Methods

Basic querying, filtering, and sorting is provided out-of-the-box, so the following shouldn't be needed for basic usage. But, in some cases you might need to just change the implementation. In fact you may choose to do this in all of your controllers if you wish, such that RESTful JSON would only be providing the JSON formatting and, optionally, CORS.

To do this, you may implement some or all of the following methods: index_it, show_it, create_it, update_it, and/or destroy_it. These correspond to the index, show, create, update, and destroy methods in the RESTful JSON parent controller.

For example, to have basic filtering behavior in the index and basic show/create/update/destroy, you might use:

    def index_it(model_class)
      value = model_class.scoped
      allowed_activerecord_model_attribute_keys.each do |attribute_key|
        param = params[attribute_key]
        value = value.where(attribute_key => param) if param.present?
      end
      value
    end

    def show_it(model_class, id)
      model_class.find(id)
    end

    def create_it(model_class, data)
      model_class.new(data)
    end

    def update_it(model_class, id)
      model_class.find(id)
    end

    def destroy_it(model_class, id)
      model_class.find(id).destroy
    end

You can also use custom variable names that make the code clearer to read. For example, in our Foobar example, you might use:

    def show_it(foobar_class, foobar_id)
      foobar_class.find(foobar_id)
    end

or even ignore the passed in Foobar class and use your own. (This may not look as clear, though.):

    def show_it(foobar_class, foobar_id)
      Foobar.find(foobar_id)
    end

However, if you have some great generic code you are adding to all of your controllers to override, it might be better to fork the restful_json gem or extend it with your own gem, if it is something others could use.

#### Refactoring Customized Controllers

You could extend it locally with your own custom parent controller.

For example, you would do this in app/controllers/my_base_controller.rb to scope the index query to only show data from the beginning of the year (UTC), while still providing some basic dynamic filtering:

    class YearScopingController < ApplicationController

      def index_it(model_class)
        value = model_class.scoped
        value = value.where("created_at <= ?", Time.utc(Time.now.year, 1, 1))
        allowed_activerecord_model_attribute_keys.each do |attribute_key|
          param = params[attribute_key]
          value = value.where(attribute_key => param) if param.present?
        end
        value
      end

    end

and then multiple controllers could use that, assuming they have an attribute called created_at:

    class FoobarController < YearScopingController
    end
    
    class BarfooController < YearScopingController
    end

#### CORS

If you have javascript/etc. code in the client that is running under a different host or port than Rails server, then you are cross-origin/cross-domain and we handle this with [CORS][cors].

By default CORS is disabled, so to enable it you can either set the environment variable RESTFUL_JSON_CORS_GLOBALLY_ENABLED, or in config/environment.rb or for a specific environment like config/environments/development.rb you can add the following global variable:

    $restful_json_cors_globally_enabled = true

By default, we make CORS just allow everything, so the whole cross-origin/cross-domain thing goes away and you can get to developing locally with your Javascript app that isn't even being served by Rails.

##### Advanced CORS Usage

So, if you enabled CORS, then CORS starts with a [preflight request][preflight_request] from the client (the browser), to which we respond with a response. You can customize the values of headers returned in the :cors_preflight_headers option. Then for all other requests to the controller, you can specify headers to be returned in the :cors_access_control_headers option.

Here's an example of customizing both:

    class MyModelController < ApplicationController
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

### License

Copyright (c) 2012 Gary S. Weaver, released under the [MIT license][lic].

[ember_data_example]: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
[angular]: http://angularjs.org/
[cors]: http://enable-cors.org/
[preflight_request]: http://www.w3.org/TR/cors/#resource-preflight-requests
[lic]: http://github.com/garysweaver/activerecord-attribute-override/blob/master/LICENSE
