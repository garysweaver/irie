RESTful JSON v2 for Rails 3.x
=====

A gem that loads a class called RestfulJson::Controller that extends your ApplicationController that you can use to easily make controllers in Rails 3.x that dynamically add RESTful JSON methods to your controllers to reduce code clutter and just focus on the javascript (or whatever makes you happy these days) frontend that interacts with it.

The intent is to allow a simple way to use Rails as a RESTful JSON service backend for a javascript-based front-end. Some believe that you should have the boilerplate code all over your controllers, which you may decide is better for you, but using restful-json will save you some code and opts for a simpler implementation.

The original controller implementation borrowed heavily from Dan Gebhardt's example in [ember_data_example][ember_data_example], but we are using it with [AngularJS][angular].

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

### The JSON services

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

#### NULL

To specify a null value for filtering or predication value, by default you can use NULL, null, or nil, so any of these would mean you want to find Foobars where the color is not set:

    http://localhost:3000/foobars.json?color=NULL
    http://localhost:3000/foobars.json?color=null
    http://localhost:3000/foobars.json?color=nil

If you want to change this behavior for a specific param or for all, you may implement convert_request_param_value_for_filtering in your controller. For example, if empty params or those only containing only spaces should be null, e.g. 'http://localhost:3000/foobars.json?color=' or http://localhost:3000/foobars.json?color=  ', then you'd put this into the controller:

    def convert_request_param_value_for_filtering(attr_name, value)
      value && ['NULL','null','nil',''].include?(value.strip) ? nil : value
    end

#### Support for AREL predications

By specifying a character that identifies an AREL predication is suffixed to the request parameter name after a character you can customize, you can help filter data even further:

    http://localhost:3000/foobars.json?foo_date!gteq=2012-08-08

We currently support the following AREL predications: does_not_match, does_not_match_all, does_not_match_any, eq, eq_all, eq_any, gt, gt_all, gt_any, gteq, gteq_all, gteq_any, in, in_all, in_any, lt, lt_all, lt_any, lteq, lteq_all, lteq_any, matches, matches_all, matches_any, not_eq, not_eq_all, not_eq_any, not_in, not_in_all, and not_in_any:

    http://localhost:3000/foobars.json?foo_date!eq_any=2012-08-08,2012-09-09

To limit AREL predications that are supported, you can override supported_arel_predications(attr_name=nil) in your controller if you want. Here are the defaults:

    def supported_arel_predications(attr_name=nil)
      ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
        'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
        'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
        'not_in', 'not_in_all', 'not_in_any']
    end

To change the AREL predication delimiter in the controller, change the '!' to something else:

    def arel_predication_split
      '!'
    end

To change the split for multiple values in the controller, change the ',' to something else:

    def value_split
      ','
    end

For some predications, we don't split, just to not split for something we can't take a multiple value for anyway. Here are the defaults:

    def multiple_value_arel_predications(attr_name=nil)
      ['does_not_match_all', 'does_not_match_any', 'eq_all', 'eq_any', 'gt_all', 
       'gt_any', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt_all', 'lt_any', 
       'lteq_all', 'lteq_any', 'matches_all', 'matches_any', 'not_eq_all', 'not_eq_any', 
       'not_in', 'not_in_all', 'not_in_any']
    end

#### Only

To return a simple view of a model, use the only param. This limits both the select in the SQL used and the json returned. e.g. to return the name and color attributes of foobars:

    http://localhost:3000/foobars.json?only=name,color

#### Uniq

To return a simple view of a model, use the uniq param. This limits both the select in the SQL used and the json returned. e.g. to return unique/distinct colors of foobars:

    http://localhost:3000/foobars.json?only=color&uniq=

#### Skip

To skip rows returned, use 'skip'. It is called take, because skip is the AREL equivalent of SQL OFFSET:

    http://localhost:3000/foobars.json?skip=5

#### Take

To limit the number of rows returned, use 'take'. It is called take, because take is the AREL equivalent of SQL LIMIT:

    http://localhost:3000/foobars.json?take=5

#### Paging results

Combine skip and take for manual completely customized paging.

Get the first page of 15 results:

    http://localhost:3000/foobars.json?take=15

Second page of 15 results:

    http://localhost:3000/foobars.json?skip=15&take=15

Third page of 15 results:

    http://localhost:3000/foobars.json?skip=30&take=15

First page of 30 results:

    http://localhost:3000/foobars.json?take=30

Second page of 30 results:

    http://localhost:3000/foobars.json?skip=30&take=30

Third page of 30 results:

    http://localhost:3000/foobars.json?skip=60&take=30


#### No associations

To return a view of a model without associations, even if those associations are defined to be displayed via as_json_includes, use the no_associations param. e.g. to return the foobars accessible attributes only:

    http://localhost:3000/foobars.json?no_includes=

#### Some associations

To return a view of a model with only certain associations that you have rights to see, use the associations param. e.g. if the foo, bar, boo, and far associations are exposed via as_json_includes and you only want to show the foos and bars:

    http://localhost:3000/foobars.json?include=foos,bars

### Models

ActiveRecord::Base gets a few new class methods and new as_json behavior!  

#### JSON format

as_json is extended to include methods/associations specified in as_json_includes, e.g.:

    as_json_includes :association_name_1, :association_name_2

So, if you want to automatically accept json association data in put/post and include it in the json that is emitted by the services, you'd do:

    accepts_nested_attributes_for :association_name_1, :association_name_2
    as_json_includes :association_name_1, :association_name_2

#### Including non-mass-assignable attributes in the JSON

To include extra non-mass-assignable attributes in the json, add those to as_json_includes. id is a common attribute that needs to be returned in the json but you should be allowed to set:

    accepts_nested_attributes_for :association_name_1, :association_name_2
    as_json_includes :association_name_1, :association_name_2

#### IDs are included by default

Most of the time when working with a RESTful service, you'll want it to return the id of each object. This is done by default. If your object doesn't have an ID or you don't want it included, you can specifically exclude it, e.g.:

    as_json_excludes :id

#### Excluding other attributes and associations

    as_json_excludes :foo, :bars

##### Circular references avoided

If an object has already been expanded into its associations, if it is referenced again, as_json only emits JSON for the object's accessible attributes, not its associations.

### Controller

#### Do updates without having to put the id in the URL, just put the id in the JSON

Enabled by default.

The controller can just figure out whether it is a create by no 'id' being set in the JSON and an update of the 'id' is set. No need to worry about POST, PUT methods or the URL, just POST everything to the create URL.

You can change this by setting the RESTFUL_JSON_INTUIT_POST_OR_PUT_METHOD environment variable or the global variable $restful_json_intuit_post_or_put_method in your environment.rb:

      $restful_json_intuit_post_or_put_method = false

Or via overriding the following method on the controller:
      
      def restful_json_intuit_post_or_put_method
        ENV['RESTFUL_JSON_INTUIT_POST_OR_PUT_METHOD'] || $restful_json_intuit_post_or_put_method || true
      end

#### Scavenge bad associations for ID

Enabled by default.

Use this with restful_json_ignore_bad_attributes and if you pass in JSON with associations set to their full JSON representation, it will mine the JSON for an 'id' which it will then create a key for in the request JSON corresponding to the foreign id that you probably meant to set if the association is a belongs_to or has_and_belongs_to_many.

You can change this by setting the RESTFUL_JSON_SCAVENGE_BAD_ASSOCIATIONS_FOR_ID_ONLY environment variable or the global variable $restful_json_scavenge_bad_associations_for_id_only in your environment.rb:

      $restful_json_scavenge_bad_associations_for_id_only = false

Or via overriding the following method on the controller:
      
      def restful_json_scavenge_bad_associations_for_id_only
        ENV['RESTFUL_JSON_SCAVENGE_BAD_ASSOCIATIONS_FOR_ID_ONLY'] || $restful_json_scavenge_bad_associations_for_id_only || true
      end

#### Ignore attributes and associations you didn't mean to pass in the JSON

Enabled by default.

You can change this by setting the RESTFUL_JSON_IGNORE_BAD_ATTRIBUTES environment variable or the global variable $restful_json_ignore_bad_attributes in your environment.rb:

      $restful_json_ignore_bad_attributes = false

Or via overriding the following method on the controller:
      
      def restful_json_ignore_bad_attributes
        ENV['RESTFUL_JSON_IGNORE_BAD_ATTRIBUTES'] || $restful_json_ignore_bad_attributes || true
      end
      
#### You don't have to specify *_attributes in POSTed or PUT JSON when using accepts_nested_attributes_for

Enabled by default.

With accepts_nested_attributes_for, Rails/ActiveRecord expects you to specify the key in the provided JSON by suffixing the key with _attributes, e.g. if you want to specify FlightCrewMembers on Airplane, you would have had to have sent in flight_crew_members_attributes instead of flight_crew_members. With restful_json, you only need to pass in flight_crew_members as the key as you'd expect.

You can change this by setting the RESTFUL_JSON_SUFFIX_ATTRIBUTES environment variable or the global variable $restful_json_suffix_attributes in your environment.rb:

      $restful_json_suffix_attributes = false

Or via overriding the following method on the controller:
      
      def restful_json_suffix_attributes
        ENV['RESTFUL_JSON_SUFFIX_ATTRIBUTES'] || $restful_json_suffix_attributes || true
      end

#### With parameter wrapping

Our AngularJS integration seemed to be easier without any wrapping, so by default RESTful JSON does not wrap response data. You can change this and have it take and specify the singular or plural model name by setting the RESTFUL_JSON_WRAPPED environment variable or the global variable $restful_json_wrapped in your environment.rb:

    $restful_json_wrapped=true

Or in the controller, you can specify:

    def restful_json_wrapped
      true
    end

#### Customizing ActiveRecord queries/methods

Basic querying, filtering, and sorting is provided out-of-the-box, so the following shouldn't be needed for basic usage. But, in some cases you might need to just change the implementation. In fact you may choose to do this in all of your controllers if you wish, such that RESTful JSON would only be providing the JSON formatting and, optionally, CORS.

To do this, you may implement some or all of the following methods: index_it, show_it, create_it, update_it, and/or destroy_it. These correspond to the index, show, create, update, and destroy methods in the RESTful JSON parent controller.

For example, a very basic unwrapped implementation (note: @request_json is automatically determined and set by index, show, create, update, and destroy that call these methods):

    def index_it
      @value = Foo.all
    end

    def show_it
      @value = Foo.find(params[:id])
    end

    def create_it
      @value = Foo.new(@request_json)
      @value.save
    end

    def update_it
      @value.update_attributes(@request_json)
    end

    def destroy_it
      Foo.where(id: params[:id]).first ? Foo.destroy(params[:id]) : true
    end

A basic abstract controller might contain (note: @model_class is automatically set based on controller name in every controller):

    def index_it
      @value = @model_class.all
    end

    def show_it
      @value = @model_class.find(params[:id])
    end

    def create_it
      @value = @model_class.new(@request_json)
      @value.save
    end

    def update_it
      @value.update_attributes(@request_json)
    end

    def destroy_it
      @model_class.where(id: params[:id]).first ? @model_class.destroy(params[:id]) : true
    end

### CORS

If you have javascript/etc. code in the client that is running under a different host or port than Rails server, then you are cross-origin/cross-domain and we handle this with [CORS][cors].

By default CORS is disabled, so to enable it you can either set the environment variable RESTFUL_JSON_CORS_ENABLED, or in config/environment.rb or for a specific environment like config/environments/development.rb you can add the following global variable:

    $restful_json_cors_enabled = true

Or in the controller, you can specify:

    def restful_json_cors_enabled
      true
    end

By default, we make CORS just allow everything, so the whole cross-origin/cross-domain thing goes away and you can get to developing locally with your Javascript app that isn't even being served by Rails.

##### Advanced CORS usage

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
[lic]: http://github.com/garysweaver/restful_json/blob/master/LICENSE
