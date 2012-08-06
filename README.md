RESTful JSON v2 for Rails 3.x
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

So if you had an existing model app/models/foobar.rb:

    class Foobar < ActiveRecord::Base
    end

You would do this in app/controllers/foobar_controller.rb:

    class FoobarsController < ApplicationController
      acts_as_restful_json
    end

Then in config/routes.rb, you would add the following. This will set up normal Rails resourceful routes to the Foobar resource, and restrict it to only serving json format:

    resources :foobars, :constraints => {:format => /json/}

That's it. Now you can serve up some Javascript in one of your views that hits the RESTful services that have been defined.

Just start the Rails server:

    rails s

### The JSON Services

#### Basics

Take a look at the output of 'rake routes' to see the paths for /foobar and then construct URLs to test it:

    rake routes

For our example above, you could then list all Foobars with a GET to what equates to the "list" command:

    http://localhost:3000/foobars.json

To find out what the JSON to use as the 'foobar' parameter value, you could create one first in Rails console and then get that or call to_json on it in the console.

Get a Foobar with id '1' with a GET method call to the following:

    http://localhost:3000/foobars/1.json

Create a Foobar with with a POST method call to the following, setting the JSON of a new Foobar as input/request parameter 'foobar':

    http://localhost:3000/foobars/new.json

Update a Foobar with id '1' with a PUT method call to the following:

    http://localhost:3000/foobar/1.json

Destroy a Foobar with id '1' with a DELETE method call to the following:

    http://localhost:3000/foobar/1.json

#### Filtering

Attributes marked as accessible in the model can be queried by specifying the value of the request parameter as the attribute in the list query.

For example, if Foobar were to have an ActiveRecord attribute called "color" (because the backing database table has a column named color), you could do:

    http://localhost:3000/foobars.json?color=blue

Note: Don't use any of these methods to allow or filter anything secure. If a user has access to the controller method, they have access to any format you define with one of these methods via the json_format request parameter or faking referer. The primary reason for these filters are to limit associations- not for security, but to reduce data returned in the request, thereby reducing traffic and time required for response.

#### Only

To return a simple view of a model, use the only param. This limits both the select in the SQL used and the json returned, e.g. to return the name and color attributes of foobars:

    http://localhost:3000/foobars.json?only=name,color

#### Uniq

To return a simple view of a model, use the uniq param. This limits both the select in the SQL used and the json returned, e.g. to return unique/distinct colors of foobars:

    http://localhost:3000/foobars.json?only=color&uniq=

#### JSON format

as_json is extended to include attributes specified in default_as_json_includes, e.g.:

    default_as_json_includes :association_name_1, :association_name_2

So, if you want to automatically accept json association data in put/post and include it in the json that is emitted by the services, you'd do:

    accepts_nested_attributes_for :association_name_1, :association_name_2
    default_as_json_includes :association_name_1, :association_name_2

#### And Some Things Are Just a Little Bit Easier

##### 'id' Included in JSON

If you are setting a custom primary key via set_primary_key or self.primary= in your model, or using the composite_primary_keys gem, there is an 'id' attribute added to the attributes in every object returned (and its associations, and their associations, etc.) that contains the id that you would expect in the returned JSON (and whenever as_json is called).

##### You don't have to specify *_attributes when using accepts_nested_attributes_for

With accepts_nested_attributes_for, Rails/ActiveRecord expects you to specify the key in the provided JSON by suffixing the key with _attributes, e.g. if you want to specify FlightCrewMembers on Airplane, you would have had to have sent in flight_crew_members_attributes instead of flight_crew_members. With restful_json, you only need to pass in flight_crew_members as the key as you'd expect.

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

      acts_as_restful_json

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

    class FoobarsController < YearScopingController
    end
    
    class BarfoosController < YearScopingController
    end

#### CORS

If you have javascript/etc. code in the client that is running under a different host or port than Rails server, then you are cross-origin/cross-domain and we handle this with [CORS][cors].

By default CORS is disabled, so to enable it you can either set the environment variable RESTFUL_JSON_CORS_GLOBALLY_ENABLED, or in config/environment.rb or for a specific environment like config/environments/development.rb you can add the following global variable:

    $restful_json_cors_globally_enabled = true

By default, we make CORS just allow everything, so the whole cross-origin/cross-domain thing goes away and you can get to developing locally with your Javascript app that isn't even being served by Rails.

##### Advanced CORS Usage

So, if you enabled CORS, then CORS starts with a [preflight request][preflight_request] from the client (the browser), to which we respond with a response. You can customize the values of headers returned in the :cors_preflight_headers option. Then for all other requests to the controller, you can specify headers to be returned in the :cors_access_control_headers option.

Here's an example of customizing both:

    class FoobarsController < ApplicationController
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
[as_json]: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html#method-i-as_json
[cors]: http://enable-cors.org/
[preflight_request]: http://www.w3.org/TR/cors/#resource-preflight-requests
[lic]: http://github.com/garysweaver/activerecord-attribute-override/blob/master/LICENSE
