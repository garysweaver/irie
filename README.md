restful_json v3 for Rails 3.1+
=====

restful_json makes creating JSON APIs that have REST-like behavior as easy as:

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

And to create or update a Foobar, you can just post/put JSON to:

    http://localhost:3000/foobar

Some highlights:
* Application-level configuration, and controller-level configuration via class attributes.
* Configurably filter results using URL parameters as desired or lock it down.
* Override only what you need to stay [DRY][dry].
* Supports Rails [mass assignment security][mass_assignment_security].
* Configurable support for:
  * [Cross-origin resource sharing (CORS)][cors].
  * Filtering via [AREL][arel_predications], nil/null values, unique, only, include, and more.
  * Ignoring non-mass-assignable attributes and associations in incoming JSON for creates/updates.
  * Paging results via count, skip (start index), and take (limit).
  * Removing need for _attributes suffix to update associations.
  * Returning one or more associations and/or custom methods in JSON.
  * Session authentication with controller and action restriction.
  * Updating associations via JSON.

Ruby on Rails can be an excellent choice for serving up heavy client-side Javascript, providing a wealth of functionality through available gems, and providing the ability to write a gem to make service development trivial.

Our take on things has been continuing to evolve, but the overall goal of the project remains to be that providing restful_json APIs via Rails for use in javascript frameworks should be as simple, DRY, fun and flexible as possible. Please let us know if you'd like to contribute.

### Alternatives

If you only need to provide a Rest API in Rails (even though you should then consider Sinatra, Node, etc. also), check out [rails-api][rails-api] and see [Railscast #348][railscast348].

### Disclaimer

A lot of things are said to implement REST and be RESTful that aren't by Roy T. Fielding's [definition][rest_apis_must_be_hypertext_driven]. Rails controllers' default behavior is a lot closer to Roy's original intent than this project. restful_json is JSON-only and doesn't use hyperlinks or discovery.

However, we are trying to stay true to the goal of making it easier to provide services that may at least partially fit the definition enough to be compatible with client code that you might choose to develop using Javascript frameworks that integrate with what they understand to be "RESTful services".

We could change the name of the project to something else, but it works for us!

### Setup

In your Rails 3+ project, add this to your Gemfile:

    gem 'restful_json', :git => 'git://github.com/garysweaver/restful_json.git'

Then run:

    bundle install

To stay up-to-date, periodically run:

    bundle update restful_json

### Usage

So if you had an existing model `app/models/foobar.rb`:

    class Foobar < ActiveRecord::Base
    end

You would do this in `app/controllers/foobar_controller.rb`:

    class FoobarsController < ApplicationController
      acts_as_restful_json
    end

Then in `config/routes.rb`, you would add the following. This will set up normal Rails resourceful routes to the Foobar resource, restrict it to only serving json format, and remove the requirement to specify the .json extension:

    resources :foobars, :constraints => {:format => /json/}, :defaults => {:format => 'json'}

That's it. Now you can serve up some Javascript in one of your views that hits the restful_json services that have been defined.

Just start the Rails server:

    rails s

### The JSON services

#### Basics

Take a look at the output of `rake routes` to see the paths for `/foobar` and then construct URLs to test it:

    rake routes

For our example above, you could then list all Foobars with a GET to what equates to the "list" command:

    http://localhost:3000/foobars

Get a Foobar with id '1' with a GET method call to the following:

    http://localhost:3000/foobars/1

Create a Foobar with with a POST method call to the following, setting the JSON of a new Foobar with JSON simmilar to what you would have gotten from a GET except without an id:

    http://localhost:3000/foobars

Update a Foobar with id '1' with a PUT method call to the following:

    http://localhost:3000/foobar/1

OR just do a POST or PUT like you would a create and put the id in the JSON:

    http://localhost:3000/foobars

Destroy a Foobar with id '1' with a DELETE method call to the following:

    http://localhost:3000/foobar/1

#### Filtering

Attributes marked as accessible in the model can be queried by specifying the value of the request parameter as the attribute in the list query.

For example, if Foobar were to have an ActiveRecord attribute called "color" (because the backing database table has a column named color), you could do:

    http://localhost:3000/foobars?color=blue

To disable the ability to do this query, remove 'eq' from `supported_arel_predications` via configuration or setting in the controller.

#### NULL

To specify a null value for filtering or predication value, by default you can use NULL, null, or nil, so any of these would mean you want to find Foobars where the color is not set:

    http://localhost:3000/foobars?color=NULL
    http://localhost:3000/foobars?color=null
    http://localhost:3000/foobars?color=nil

If you want to change this behavior for a specific param or for all, you may implement `convert_request_param_value_for_filtering` in your controller. For example, if empty params or those only containing only spaces should be null, then you'd put this into the controller:

    def convert_request_param_value_for_filtering(attr_name, value)
      value && ['NULL','null','nil',''].include?(value.strip) ? nil : value
    end

#### Support for AREL predications

Append a '!' and an [AREL predication][arel_predications] to the request parameter name, e.g. to get Foobars with seen_on of 2012-08-08 or later, you'd use:

    http://localhost:3000/foobars?seen_on!gteq=2012-08-08

We currently try to support all AREL predications, even the ones that take multiple values:

    http://localhost:3000/foobars?seen_on!eq_any=2012-08-08,2012-09-09

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

To return a view of a model without associations, use the `no_includes` param. e.g. to return the foobars accessible attributes only:

    http://localhost:3000/foobars?no_includes=

#### Some associations

To return a view of a model with only certain associations that you have rights to see, use the associations param. e.g. if the foo, bar, boo, and far associations would have been returned, but you only want to show the foos and bars:

    http://localhost:3000/foobars?include=foos,bars

### Wrapped or unwrapped JSON

The standard Rails 3+ way of doing this is to tell the controller whether or not to convert unwrapped json in the request the following two configuration bit that are found in `config/initializers/wrap_parameters.rb`:

    # Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
    ActiveSupport.on_load(:action_controller) do
      wrap_parameters format: [:json]
    end

    # Disable root element in JSON by default.
    ActiveSupport.on_load(:active_record) do
      self.include_root_in_json = false
    end

Summary:
* `wrap_parameters` controls whether you want the services to expect `{foobars: => ...}` or `{...}`.
* `include_root_in_json` controls whether you want the services to output `{foobars: => ...}` or `{...}`.

### Controller

#### Controller-level configuration

There are class_attributes available to be set for any item in the controller section in the Configuration section below.

In addition, there are some things the controller also lets you set. If you don't want to use the normal FoobarsController or SomeModule::FoobarsController for Foobar model naming convention then you can override the model_class here:

    self.model_class = Foobar

That will also set the singular and plural model name which is used for wrapping. It is doubtful, but if really needed, you can also configure them:

    self.model_singular_name = 'foobar'
    self.model_plural_name = 'foobars'

#### Customizing ActiveRecord queries/methods

You don't have to specify these methods.

The restful_json's default implementation of these should be fine, but, restful_json was built to be extensible.

Although you can override index, show, create, and update for full control, if anything, you often will just care about how it gets, creates, updates, and destroys data. This can be controlled by overriding the `index_it`, `show_it`, `create_it`, `update_it`, and/or `destroy_it` methods. These correspond to the index, show, create, update, and destroy methods in the restful_json parent controller.

There are a handful of variables that you use in a restful_json controller:
* `params`: this is a hash of request parameters along with a few other things.
* `@model_class`: the Ruby class object for the model which it either gets from self.model_class you set or using the singular form of the controller class name without "Controller" at the end.
* `@request_json`: the parsed json as a hash.
* `@value`: the default implementations of the index, show, create, and update methods expect you to set this to the instance that should be converted to JSON and returned to the client.
* `@errors`: if you `begin` and `rescue => e` you can set errors like `@errors = {errors: [e.message]}` in the rescue block, and these will be returned by default as JSON with HTTP Status Code 500. You do not need to use this for normal validation, etc. errors returned in @value.errors automatically as part of an ActiveRecord create/update, which return an hash of attribute_name/column_name an to array of error messages (even if is a single error message, which is more often the case).
* `@error_type`: if `@errors` is not nil, it will use this error code. Only use one of the allowed symbols. In `rails c` do `require 'pp';pp Rack::Utils::SYMBOL_TO_STATUS_CODE;nil` to see a list and see [List of HTTP Status Codes][status_codes] for more info.

For example, a very basic unwrapped implementation (note: `@request_json` is automatically determined and set by index, show, create, update, and destroy that call these methods):

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

#### Custom processing of incoming, outgoing data

The index, show, create, update, and destroy functions have hooks.

So, if the client was sending an HTTP header called item_name to FoobarsController and you want to look up the item_id for it and set it in the json before persisting like `{..., 'item_id': '1234', ...}`, you would do:

      def before_create_or_update_it
        @request_json['item_id'] = Item.find_by_name(request.env['HTTP.item_name']).try(:id)
      end

Note that in addition to doing this by looking at headers you can look at request params with params[:your_request_parameter_name] and can access the incoming json hash with @request_json. However, if you are strictly wanting to do pre-save changes to a model using the model's existing attributes or methods/etc. or anything the model can access, you should consider doing that in a hook on the model (see [ActiveRecord::Callbacks][callbacks]).

##### Order of hook and *_it function execution

*index*:
1. before_index_it
2. index_it if no @errors
3. after_index_it if no @errors

*show*:
1. before_show_it
2. show_it if no @errors
3. after_show_it if no @errors

*create*:
1. before_create_or_update_it
2. before_create_it if no @errors
3. create_it if no @errors
4. after_create_it if create_it returned non-nil/non-false and no @errors
5. after_create_or_update_it if create_it returned non-nil/non-false and no @errors

*update*:
1. before_create_or_update_it
2. before_update_it if no @errors
3. update_it if no @errors
4. after_update_it if update_it returned non-nil/non-false and no @errors
5. after_create_or_update_it if update_it returned non-nil/non-false and no @errors

*destroy*:
1. before_destroy_it
2. destroy_it if no @errors
3. after_destroy_it if destroy_it returned non-nil/non-false and no @errors

#### ROAR

[ROAR][roar] (actually roar-rails, but ROAR is the part you'll use) is used for mapping JSON to models for persistence and for JSON deserialization (view) from models.

The representer handles what JSON is taken, persisted, and in some cases, what JSON is spit back out.

The collection representer is usually used for index, and the entity representer is used for the other methods.

By default we use a representer that just contains the accessible attributes and one level of associations, but we hope you'll do more than just that.

Note: representer for index can be overriden for the context of the request ala `respond_with @value, :represent_items_with => index_representer` by overriding the `index_representer` method in your controller, which is executed within index_it.

The representer handles what JSON is taken, persisted, and in some cases, what JSON is spit back out.

Representers for these can be overriden for the context of the request ala `respond_with @value, :represent_items_with => index_representer` by overriding the `show_representer`, `create_representer`, or `update_representer` methods in your controller to return the right representer module. This method is called within show_it, create_it, or update_it methods, e.g.

    def index_representer
      params[:saucy] ? MyProject::SaucyRepresenter : MyProject::BlandRepresenter
    end

ROAR uses [Representable][representable]. Check out its README to learn how you can map different json key names to different attributes (`property :forename, :from => :i_am_called`), render nil so nils don't come back as false (`property :surename, :render_nil => true`), use coercion (which uses [virtus][virtus]) to effectively define types of json properties (`property :born_at, :type => DateTime, :default => "May 12th, 2012"`), and more. The stuff it writes about 

### Configuration

#### General options

These options are available for the application:

##### Debug

If true, outputs verbose info on the operations of restful_json.

#### Controller options

Here are the options available for the application and each controller:

##### arel_predication_split

The character in the URL that seperates the attribute name from the optional arel predication

##### cors_access_control_headers

A hash of headers to use for each non-preflight response

##### cors_enabled

True to enable [CORS][cors]. If you have javascript/etc. code in the client that is running under a different host or port than Rails server, then you are cross-origin/cross-domain and we handle this with CORS. By default, we make CORS just allow everything, so the whole cross-origin/cross-domain thing goes away and you can get to developing locally with your Javascript app that isn't even being served by Rails.

##### cors_preflight_headers

So, if you enabled CORS, then CORS starts with a [preflight request][preflight_request] from the client (the browser), to which we respond with a response. You can customize the values of headers returned in the `cors_preflight_headers` option. Then for all other requests to the controller, you can specify headers to be returned in the `cors_access_control_headers` option. This is a hash of headers to use for each preflight response.

##### ignore_bad_json_attributes

True by default. Ignores keys that aren't accessible attributes or associations that have an `accepts_nested_attributes_for`.

##### intuit_post_or_put_method

If true, anything that comes into the create method with 'id' in the JSON will be sent to update. This way you don't need to put the ID in the URL to do an update and can reuse the same resource URL for create or update.

##### multiple_value_arel_predications

Should hopefully never have to modify this. It is a list of predications that can take multiple values, e.g. not_in_all could take multiple values.

##### roar_collection_representer

The [ROAR][roar] representer module for model collections. See the ROAR section for details.

##### roar_entity_representer

The [ROAR][roar] representer module for single model instances. See the ROAR section for details.

##### scavenge_bad_associations

If you pass in a json block for an association that is not `accepts_nested_attributes_for`, then it will look for 'id' in the root of that block, and if it finds it, it will set the foreign_key of a related `belongs_to` or `has_and_belongs_to_many` association if one exists and is mass-assignable.

If you pass in a nil for an association that is not `accepts_nested_attributes_for`, then it will set the foreign_key of a related `belongs_to` or `has_and_belongs_to_many` association to nil (if one exists and is mass-assignable).

##### suffix_json_attributes

True to automatically add _attributes to the end of keys in your JSON that correspond to valid associations.

##### supported_arel_predications

An array of arel predications. If you want to lock down what filters people can use to only certain controllers, this would be a way to do it.

##### supported_functions

An array of supported functions. See this document for a description of each function.

##### value_split

When sending multiple values in a filter in the URL, this is the delimiter.

#### Application-wide configuration

In your `config/environment.rb` or environment specfic configuration, you may specify one or more options in the config hash that will be merged into the following defaults:

    ::RestfulJson::Options.configure({
      # General options
      debug: false,

      # Controller options
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
      scavenge_bad_associations: true,
      suffix_json_attributes: true,
      supported_arel_predications: ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                     'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                     'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                     'not_in', 'not_in_all', 'not_in_any'],
      supported_functions: ['count', 'include', 'no_includes', 'only', 'skip', 'take', 'uniq'],
      value_split: ','
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
      self.scavenge_bad_associations = true
      self.suffix_json_attributes = true
      self.supported_arel_predications = ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                     'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                     'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                     'not_in', 'not_in_all', 'not_in_any']
      self.supported_functions = ['count', 'include', 'no_includes', 'only', 'skip', 'take', 'uniq']
      self.value_split = ','

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

Then, override Rails defaults to return the Javascript default format for datetimes for date, time, datetimes by putting the following in `config/environment.rb` or in a some_name.rb file somewhere under `config/initializers/` or a subdirectory:

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

[dry]: http://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[virtus]: https://github.com/solnic/virtus
[classmeta]: https://github.com/garysweaver/classmeta
[callbacks]: http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html
[rest_apis_must_be_hypertext_driven]: http://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven
[status_codes]: http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
[roar]: https://github.com/apotonick/roar
[representable]: https://github.com/apotonick/representable
[ember]: http://emberjs.com/
[ember_data_example]: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
[angular]: http://angularjs.org/
[as_json]: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html#method-i-as_json
[be_readonly]: https://github.com/garysweaver/activerecord-be_readonly
[arel_predications]: https://github.com/rails/arel/blob/master/lib/arel/predications.rb
[cors]: http://enable-cors.org/
[mass_assignment_security]: http://guides.rubyonrails.org/security.html#mass-assignment
[preflight_request]: http://www.w3.org/TR/statuscors/#resource-preflight-requests
[state_of_rails_apis]: http://broadcastingadam.com/2012/03/state_of_rails_apis/
[strong_parameters]: https://github.com/rails/strong_parameters
[cancan]: https://github.com/ryanb/cancan
[active_model_serializers]: https://github.com/josevalim/active_model_serializers
[rabl]: https://github.com/nesquena/rabl/
[rails-api]: https://github.com/spastorino/rails-api
[railscast348]: http://railscasts.com/episodes/348-the-rails-api-gem?view=asciicast 
[issue7442]: https://github.com/rails/rails/issues/7442
[lic]: http://github.com/garysweaver/restful_json/blob/master/LICENSE
