RESTful JSON v2 for Rails 3.x
=====

RESTful JSON makes creating RESTful services as easy as:

    class FoobarsController < ApplicationController
      acts_as_restful_json
    end 

Then optionally set constraints and defaults in config/routes.rb so you don't need to specify an extension:

    resources :foobars, :constraints => {:format => /json/}, :defaults => {:format => 'json'}

Then to get all blue Foobars that expire after 8/20/2012 as JSON, you could just get:

    http://localhost:3000/foobars?color=blue&expired_at!gteq=2012-08-20

Or to get the total count and page the results, you'd get:

    http://localhost:3000/foobars?color=blue&expired_at!gteq=2012-08-20&count=
    http://localhost:3000/foobars?color=blue&expired_at!gteq=2012-08-20&skip=0&take=15

And to create or update a Foobar, you can just post/put using [AngularJS][angular], or Ember by setting wrapped_json in config, to:

    http://localhost:3000/foobar

Some highlights:
* Filter results with full AREL support, nil/null support, count, unique, start index (skip), limit (take), only, include, and more.
* Lock down what attributes and what associated data can be updated by using standard Rails mass assignment security.
* Session authenticated with fully customizable controller and method level restriction to integrate with your authorization solution.
* Develop client code either in *or* outside of Rails. Can use CORS.
* Configure globally or per controller with class attributes.
* Override only what you need to stay DRY.
* Enable or disable through configuration at the controller level to lock it down.
* Optionally can return associations and custom methods in JSON, and can update assocations.

### Future

A lot is still subject to change in the next major version. [Strong Parameters][strong_parameters] is being integrated with Rails 4 as an eventual replacement for mass assignment, so we'd like to start using that. We might also start requiring some sort of authentication so there is concept of user or role, start using [CanCan][cancan] for authorization, [ActiveModel::Serializers][active_model_serializers] to replace the [as_json][as_json] extension, and maybe add support for versioning.

Thanks much to the informative post, [State of Writing API Servers with Rails][state_of_rails_apis] and the original [ember_data_example][ember_data_example] project the first version heavily borrowed from. We use [AngularJS][angular], but we have done what we could easily to support ember and other Javascript frameworks.

The overall goal of the project is to make providing RESTful JSON APIs via Rails for use in javascript frameworks as simple as possible, while still letting you override the base functionality when needed. Stay tuned and please let us know if you'd like to contribute.

### Setup

In your Rails 3+ project, add this to your Gemfile:

    gem 'restful_json', :git => 'git://github.com/garysweaver/restful_json.git'

Then run:

    bundle install

To stay up-to-date, periodically run:

    bundle update restful_json

### Usage

So if you had an existing model app/models/foobar.rb:

    class Foobar < ActiveRecord::Base
    end

You would do this in app/controllers/foobar_controller.rb:

    class FoobarsController < ApplicationController
      acts_as_restful_json
    end

Then in config/routes.rb, you would add the following. This will set up normal Rails resourceful routes to the Foobar resource, restrict it to only serving json format, and remove the requirement to specify the .json extension:

    resources :foobars, :constraints => {:format => /json/}, :defaults => {:format => 'json'}

That's it. Now you can serve up some Javascript in one of your views that hits the RESTful services that have been defined.

Just start the Rails server:

    rails s

### The JSON services

#### Basics

Take a look at the output of 'rake routes' to see the paths for /foobar and then construct URLs to test it:

    rake routes

For our example above, you could then list all Foobars with a GET to what equates to the "list" command:

    http://localhost:3000/foobars

To find out what the JSON to use as the 'foobar' parameter value, you could create one first in Rails console and then get that or call to_json on it in the console.

Get a Foobar with id '1' with a GET method call to the following:

    http://localhost:3000/foobars/1

Create a Foobar with with a POST method call to the following, setting the JSON of a new Foobar as input/request parameter 'foobar':

    http://localhost:3000/foobars

Update a Foobar with id '1' with a PUT method call to the following:

    http://localhost:3000/foobar/1

Destroy a Foobar with id '1' with a DELETE method call to the following:

    http://localhost:3000/foobar/1

#### Filtering

Attributes marked as accessible in the model can be queried by specifying the value of the request parameter as the attribute in the list query.

For example, if Foobar were to have an ActiveRecord attribute called "color" (because the backing database table has a column named color), you could do:

    http://localhost:3000/foobars?color=blue

To disable the ability to do this query, remove 'eq' from supported_arel_predications via configuration or setting in the controller.

#### NULL

To specify a null value for filtering or predication value, by default you can use NULL, null, or nil, so any of these would mean you want to find Foobars where the color is not set:

    http://localhost:3000/foobars?color=NULL
    http://localhost:3000/foobars?color=null
    http://localhost:3000/foobars?color=nil

If you want to change this behavior for a specific param or for all, you may implement convert_request_param_value_for_filtering in your controller. For example, if empty params or those only containing only spaces should be null, then you'd put this into the controller:

    def convert_request_param_value_for_filtering(attr_name, value)
      value && ['NULL','null','nil',''].include?(value.strip) ? nil : value
    end

#### Support for AREL predications

By specifying a character that identifies an [AREL predication][arel] is suffixed to the request parameter name after a character you can customize, you can help filter data even further:

    http://localhost:3000/foobars?foo_date!gteq=2012-08-08

We currently try to support all AREL predications, even the ones that take multiple values:

    http://localhost:3000/foobars?foo_date!eq_any=2012-08-08,2012-09-09

To override what predications are supported application-wide or per controller, as well as URL delimiters and what predications support multiple values, see the Configuration section of this document.

#### Only

To return a simple view of a model, use the only param. This limits both the select in the SQL used and the json returned. e.g. to return the name and color attributes of foobars:

    http://localhost:3000/foobars?only=name,color

#### Uniq

To return a simple view of a model, use the uniq param. This limits both the select in the SQL used and the json returned. e.g. to return unique/distinct colors of foobars:

    http://localhost:3000/foobars?only=color&uniq=

#### Skip

To skip rows returned, use 'skip'. It is called take, because skip is the AREL equivalent of SQL OFFSET:

    http://localhost:3000/foobars?skip=5

#### Take

To limit the number of rows returned, use 'take'. It is called take, because take is the AREL equivalent of SQL LIMIT:

    http://localhost:3000/foobars.json?take=5

#### Count

This is another filter that can be used with the others, but instead of returning the json objects, it returns their count, which is useful for paging to determine how many results you can page through:

    http://localhost:3000/foobars?count=

#### Paging results

Combine skip and take for manual completely customized paging.

Get the first page of 15 results:

    http://localhost:3000/foobars?take=15

Second page of 15 results:

    http://localhost:3000/foobars?skip=15&take=15

Third page of 15 results:

    http://localhost:3000/foobars?skip=30&take=15

First page of 30 results:

    http://localhost:3000/foobars?take=30

Second page of 30 results:

    http://localhost:3000/foobars?skip=30&take=30

Third page of 30 results:

    http://localhost:3000/foobars?skip=60&take=30

#### No associations

To return a view of a model without associations, even if those associations are defined to be displayed via as_json_includes, use the no_associations param. e.g. to return the foobars accessible attributes only:

    http://localhost:3000/foobars?no_includes=

#### Some associations

To return a view of a model with only certain associations that you have rights to see, use the associations param. e.g. if the foo, bar, boo, and far associations are exposed via as_json_includes and you only want to show the foos and bars:

    http://localhost:3000/foobars?include=foos,bars

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

#### It avoids circular references

If an object has already been expanded into its associations, if it is referenced again, as_json only emits JSON for the object's accessible attributes, not its associations.

### Controller

#### Controller-level configuration

There are class_attributes available to be set for any item in the controller section in the Configuration section below.

In addition, there are some things the controller also lets you set. If you don't want to use the normal FoobarsController or SomeModule::FoobarsController for Foobar model naming convention then you can override the model_class here:

    self.model_class = Foobar

That will also set the singular and plural model name which is used for wrapping. It is doubtful, but if really needed, you can also configure them also:

    self.model_singular_name = 'foobar'
    self.model_plural_name = 'foobars'

#### Customizing ActiveRecord queries/methods

You don't have to specify these methods.

The RESTful JSON's default implementation of these should be fine, but, RESTful JSON was built to be extensible.

Although you can override index, show, create, and update for full control, if anything, you often will just care about how it gets, creates, updates, and destroys data. This can be controlled by overriding the index_it, show_it, create_it, update_it, and/or destroy_it methods. These correspond to the index, show, create, update, and destroy methods in the RESTful JSON parent controller.

There are a handful of variables that you use in a RESTful JSON controller:
* **params**: this is a hash of request parameters along with a few other things.
* **@model\_class**: the Ruby class object for the model which it either gets from self.model_class you set or using the singular form of the controller class name without "Controller" at the end.
* **@request\_json**: the parsed json as a hash. How it gets this depends on the wrapped_json configuration parameter.
* **@value**: the default implementations of the index, show, create, and update methods expect you to set this to the instance that should be converted to JSON and returned to the client.

For example, a very basic unwrapped implementation (note: @request_json is automatically determined and set by index, show, create, update, and destroy that call these methods):

    class FoobarsController < ApplicationController

      acts_as_restful_json
  
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

    end

A basic abstract controller might contain (note: @model_class is automatically set based on controller name in every controller):

    class AbstractController < ApplicationController

      acts_as_restful_json

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

    end

### Configuration

Here are the options available for the application and each controller:

#### arel_predication_split

Character in the URL that seperates the attribute name from the optional arel predication

#### cors_access_control_headers

A hash of headers to use for each non-preflight response

#### cors_enabled

True to enable CORS. If you have javascript/etc. code in the client that is running under a different host or port than Rails server, then you are cross-origin/cross-domain and we handle this with [CORS][cors]. By default, we make CORS just allow everything, so the whole cross-origin/cross-domain thing goes away and you can get to developing locally with your Javascript app that isn't even being served by Rails.

#### cors_preflight_headers

So, if you enabled CORS, then CORS starts with a [preflight request][preflight_request] from the client (the browser), to which we respond with a response. You can customize the values of headers returned in the :cors_preflight_headers option. Then for all other requests to the controller, you can specify headers to be returned in the :cors_access_control_headers option. This is a hash of headers to use for each preflight response.

#### ignore_bad_json_attributes

True by default. Ignores keys that aren't accessible attributes or associations that have a accepts_nested_attributes_for. This should be true most likely if wrapped_json is true.

#### intuit_post_or_put_method

If true, anything that comes into the create method with 'id' in the JSON will be sent to update. This way you don't need to put the ID in the URL to do an update and can reuse the same resource URL for create or update.

#### multiple_value_arel_predications

Should hopefully never have to modify this. It is a list of predications that can take multiple values, e.g. not_in_all could take multiple values.

#### scavenge_bad_associations_for_id_only

If you pass in a json block for an association that is not accepts_nested_attributes_for, then it will look for 'id' in the root of that block, and if it finds it, it will set the foreign_key of a related belongs_to or has_and_belongs_to_many association if one exists and is mass-assignable.

#### suffix_json_attributes

True to automatically add _attributes to the end of keys in your JSON that correspond to valid associations.

#### supported_arel_predications

An array of arel predications. If you want to lock down what filters people can use to only certain controllers, this would be a way to do it.

#### supported_functions

An array of supported functions. See this document for a description of each function.

#### value_split

When sending multiple values in a filter in the URL, this is the delimiter.

#### wrapped_json

If true, then it will look for the underscored model name in the incoming JSON (in params[:your_model_name]), if false it either expects that everything in params are keys at the root of your JSON or you are sending the JSON in request body

### Application-wide configuration

In your config/environment.rb or environment specfic configuration, you may specify one or more options in the config hash that will be merged into the following defaults:

    RestfulJson::Options.configure({
      arel_predication_split: '!',
      cors_access_control_headers: {'Access-Control-Allow-Origin' => '*',
                                     'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
                                     'Access-Control-Max-Age' => '1728000'},
      cors_enabled: false,
      cors_preflight_headers: {'Access-Control-Allow-Origin' => '*',
                                'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
                                'Access-Control-Allow-Headers' => 'X-Requested-With, X-Prototype-Version',
                                'Access-Control-Max-Age' => '1728000'},
      ignore_bad_json_attributes: true,
      intuit_post_or_put_method: true,
      # Generated from Arel::Predications.public_instance_methods.collect{|c|c.to_s}.sort. To lockdown a little, defining these specifically.
      # See: https://github.com/rails/arel/blob/master/lib/arel/predications.rb
      multiple_value_arel_predications: ['does_not_match_all', 'does_not_match_any', 'eq_all', 'eq_any', 'gt_all', 
                                          'gt_any', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt_all', 'lt_any', 
                                          'lteq_all', 'lteq_any', 'matches_all', 'matches_any', 'not_eq_all', 'not_eq_any', 
                                          'not_in', 'not_in_all', 'not_in_any'],
      scavenge_bad_associations_for_id_only: true,
      suffix_json_attributes: true,
      supported_arel_predications: ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                     'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                     'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                     'not_in', 'not_in_all', 'not_in_any'],
      supported_functions: ['count', 'include', 'no_includes', 'only', 'skip', 'take', 'uniq'],
      value_split: ',',
      wrapped_json: false
    })

#### Configuring a specific controller

Any of the controller options you may also specify in the definition of the Controller class, e.g.:

      self.arel_predication_split = '!'
      self.cors_access_control_headers = nil
      self.cors_enabled = false
      self.cors_preflight_headers = nil
      self.ignore_bad_json_attributes = true
      self.intuit_post_or_put_method = true
      self.multiple_value_arel_predications = ['does_not_match_all', 'does_not_match_any', 'eq_all', 'eq_any', 'gt_all', 
                                          'gt_any', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt_all', 'lt_any', 
                                          'lteq_all', 'lteq_any', 'matches_all', 'matches_any', 'not_eq_all', 'not_eq_any', 
                                          'not_in', 'not_in_all', 'not_in_any']
      self.scavenge_bad_associations_for_id_only = true
      self.suffix_json_attributes = true
      self.supported_arel_predications = ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                     'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                     'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                     'not_in', 'not_in_all', 'not_in_any']
      self.supported_functions = ['count', 'include', 'no_includes', 'only', 'skip', 'take', 'uniq']
      self.value_split = ','
      self.wrapped_json = false

You can also configure these in a base class and inheritance should work properly since these are Rails class_attributes.

#### Dates, Times, DateTimes (and TimeWithZone)

A lot of times you just want a consistent format for date, time, or datetime, and want it to indicate the timezone.

So, set your time zone in the class in config/application.rb:

        # times are stored in DB as UTC, but we should indicate what timezone we are in
        config.time_zone = 'America/New_York'

If you are unsure what the time zone name to use is, list them by doing:

    rails c

Then:

    ActiveSupport::TimeZone.all.each do |tz|; puts "#{tz.name}"; end; nil

Or if you need to see the offset for each to choose it:

    ActiveSupport::TimeZone.all.each do |tz|; puts "#{tz}"; end; nil

Then, override Rails defaults to return the Javascript default format for datetimes for date, time, datetimes by putting the following in config/environment.rb or in a some_name.rb file somewhere under config/initializers/ or a subdirectory:

    class Time
      def as_json(options = nil) #:nodoc:
        # return UTC time in Javascript format, e.g. "2012-08-12T04:00:00.000Z"
        "#{utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')}"
        # return UTC time in format: 2012-08-20T13:24:59+0000
        #"#{utc.strftime('%Y-%m-%dT%H:%M:%S%z')}"
        # return time in current zone in format: 2012-08-20T09:26:47-0400
        #"#{strftime('%Y-%m-%dT%H:%M:%S%z')}"
      end
    end

    class Date
      def as_json(options = nil) #:nodoc:
        # return UTC time in Javascript format, e.g. "2012-08-12T04:00:00.000Z"
        "#{to_time(:utc).strftime('%Y-%m-%dT%H:%M:%S.%3NZ')}"
        # return UTC time in format: 2012-08-20T13:24:59+0000
        #"#{to_time(:utc).strftime('%Y-%m-%dT%H:%M:%S%z')}"
        # return time in current zone in format: 2012-08-20T09:26:47-0400
        #"#{to_time.strftime('%Y-%m-%dT%H:%M:%S%z')}"
      end
    end

    class DateTime
      def as_json(options = nil) #:nodoc:
        # return UTC time in Javascript format, e.g. "2012-08-12T04:00:00.000Z"
        "#{utc.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')}"
        # return UTC time in format: 2012-08-20T13:24:59+0000
        #"#{utc.strftime('%Y-%m-%dT%H:%M:%S%z')}"
        # return time in current zone in format: 2012-08-20T09:26:47-0400
        #"#{strftime('%Y-%m-%dT%H:%M:%S%z')}"
      end
    end

### License

Copyright (c) 2012 Gary S. Weaver, released under the [MIT license][lic].

[ember_data_example]: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
[angular]: http://angularjs.org/
[as_json]: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html#method-i-as_json
[arel]: https://github.com/rails/arel/blob/master/lib/arel/predications.rb
[cors]: http://enable-cors.org/
[preflight_request]: http://www.w3.org/TR/cors/#resource-preflight-requests
[state_of_rails_apis]: http://broadcastingadam.com/2012/03/state_of_rails_apis/
[strong_parameters]: https://github.com/rails/strong_parameters
[cancan]: https://github.com/ryanb/cancan
[active_model_serializers]: https://github.com/josevalim/active_model_serializers
[rabl]: https://github.com/nesquena/rabl/
[lic]: http://github.com/garysweaver/restful_json/blob/master/LICENSE
