# Restful JSON [![Build Status](https://secure.travis-ci.org/rubyservices/restful_json.png?branch=master)](http://travis-ci.org/rubyservices/restful_json)

Develop declarative, featureful JSON RESTful-ish service controllers to use with modern Javascript MVC frameworks like AngularJS, Ember, etc. with much less code.

What does that mean? It means you typically won't have to write index, create, update, destroy, etc. methods in your controllers to filter, sort, and do complex queries.

Why do you need this if Rails controllers already make it easy to provide RESTful JSON services via generated controllers? Because this is just as flexible, almost as declarative, and takes less code. That means your controllers will be easier to read and there will be less code to maintain, but when you need an action method more customized than we can provide, that's all you'll have to write.

restful_json is tested by travis-ci with with Rails 3.1, 3.2, and Rails 4. Feel free to submit issues and/or do a pull requests if you run into anything.

Your options for JSON response (the view):
* [active_model_serializers][active_model_serializers] - also provides the serialize_action class method in the controller to specify custom serializers (assuming you are using a later version of active_model_serializers that works with respond_with). 
* JBuilder - to use, set render_enabled in the restful_json config to false.
* Just about anything else that works with render/respond_with, or that just adjust the view like JBuilder, and don't require extra work in the controller.

Your options for authorizing parameters in incoming JSON (for POSTing create/update):
* Adam Hawkins' [permitters][permitter] which use [Strong Parameters][strong_parameters] and [Cancan][cancan]. Permitters are an object-oriented way of defining what is permitted in the incoming JSON, and are a great compliment in the same way that ActiveModel::Serializers are. Cancan supports [Authlogic][authlogic], [Devise][devise], etc.
* [Strong Parameters][strong_parameters] - lets you only have to define `(single model name)_params` and/or `create_(single model name)_params` and/or `update_(single model name)_params` which can call require, permit, etc. on params.
* Mass assignment security in Rails 3.x (attr_accessible, etc.).

An example app using an older version of restful_json with AngularJS is [employee-training-tracker][employee-training-tracker], featured in [Built with AngularJS][built_with_angularjs].

The goal of restful_json is to reduce service controller code in an intuitive way, not to be a be-everything DSL. You can choose whether or not to use it and what features to expose at the controller-level, and you can customize controllers and re-define actions/define custom actions.

### Installation

In your Rails app's `Gemfile`:

    gem 'restful_json', '~> 3.3.0'

And if you go with the defaults to use ActiveModel::Serializers and Permitters (using Strong Parameters and Cancan):

    # comment this out if you don't want to use Strong Parameters or Permitters, or if you are using Rails 4, which includes it
    gem 'strong_parameters', '~> 0.1.6'
    # comment this out if you don't plan to use Permitters
    gem 'cancan', '~> 1.6.8'
    # comment this out if you don't plan to use ActiveModel::Serializers
    gem 'active_model_serializers', '~> 0.6.0'
    
Then:

    bundle install

#### Service Controller Additions

To clean up your controllers and to make restful_json more flexible and less complex, we suggest use of a module to hold the includes that you'll need depending on what you decide to use. We'll call it ServiceControllerAdditions:

Create a file called `app/controllers/service_controller_additions.rb` and put this in it:

    module ServiceControllerAdditions
      extend ActiveSupport::Concern
      
      included do
        # comment this out if you don't want to use ActiveModel::Seriaizers
        include ::ActionController::Serialization
        # comment this out if you don't want to use Strong Parameters or Permitters
        include ::ActionController::StrongParameters
        # comment this out if you don't want to use Permitters
        include ::TwinTurbo::Controller
        # comment this out if you don't want to use restful_json
        include ::RestfulJson::Controller
      end
      
    end

That way you can just put this at the top of your controller, and will be able to easily extend the functionality of multiple controllers at once, e.g.:

    class FoobarsController < ApplicationController
      include ServiceControllerAdditions
    end

However, if you plan to use Permitters and ActiveModel::Serializers, use the "default". It is called the default, because v3 started off with Permitters and ActiveModel::Serializers controller, etc. includes being done by the restful_json gem, which no longer happens:

    class FoobarsController < ApplicationController
      include RestfulJson::DefaultController
    end

`acts_as_restful_json` was deprecated in restful_json 3.3.0. It just calls `include RestfulJson::DefaultController`.

#### Strong Parameters

If you plan to use Permitters or if you want to use Strong Parameters by itself, you will need to tweak things for [Strong Parameters][strong_parameters] if using Rails 3.x.

To disable the default whitelisting that occurs in later versions of Rails 3.x, set the `config.active_record.whitelist_attributes` property in your `config/application.rb` to false:

    config.active_record.whitelist_attributes = false

No more attr_accessible needed in your models (so take them out and convert them). Instead you will put this information into your permitters or into `create_(single model name)_params`, `update_(single model name)_params`, and/or `(single model name)_params` methods. Encapsulating what params are permissible in such a method is encouraged and described in the [Strong Parameters][strong_parameters] documentation, used by Rails 4.

Strong Parameters (and Permitters) require a model include.

Put this in each model you want to use Strong Parameters with:

    include ActiveModel::ForbiddenAttributesProtection

If you'd rather use Strong Parameters with all models, just put this in your `config/environment.rb`:

    ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)

#### Cancan

If you are using Permitters, they use [Cancan][cancan], which requires a `current_user` method in your `app/controllers/application_controller.rb` or in your service controllers:

    class ApplicationController < ActionController::Base
      protect_from_forgery

      def current_user
        User.new
      end
    end

You could do that better by setting up some real authentication with [Authlogic][authlogic], [Devise][devise], or whatever Cancan will support.

You also need a `app/models/ability.rb`, setup a basic cancan ability. Just for testing we'll allow everything:

    class Ability
      include CanCan::Ability

      def initialize(user)
        can :manage, :all
      end
    end

Put this in each model you want to use Cancan with:

    include CanCan::ModelAdditions

Or, if you'd rather use Cancan with all models, just put this in your `config/environment.rb`:

    ActiveRecord::Base.send(:include, CanCan::ModelAdditions)

If you follow the code above, you'll need a User model, too. Instead of providing a sample one here, we'll leave that open for you to decide on an appropriate implementation after you read through [Authlogic][authlogic], [Devise][devise], etc.

#### JSON Response Generators

##### ActiveModel Serializers

If you chose to use, [ActiveModel::Serializers][active_model_serializers], you'll eventually want to create one or more serializers for each model that you will be returning via the service(s), e.g.:

    /app/serializers/singular_model_name_serializer.rb

Without having to do anything else, each restful_json controller will use `/app/serializers/singular_model_name_serializer.rb`, e.g. `/app/serializers/bar_serializer.rb` for the actions: index, show, new, create, update, destroy (not edit).

If you want to define a different serializer another action, e.g. the index action so that a list of instances has a different JSON format:

    serialize_action :index, with: BarsSerializer

You can also use a specific format for multiple actions:

    serialize_action :index, :my_other_list_action, with: BarsSerializer

The built-in actions that support custom serializers (you can add more) are: index, show, new, create, update, destroy, and any action you automatically have created via using the restful_json `query_for` method (keep reading!).

You can just use the default serialization provided by AMS if you want. No class needed.

Because of some issues with some versions of ActiveModel::Serializers using respond_with, you might want to set the option:

    RestfulJson.avoid_respond_with = true

Otherwise, custom serializers, etc. might not be used as intended.

##### JBuilder

If you want to use JBuilder instead to render, first:

    gem 'jbuilder'

If you want to enable JBuilder for all restful_json services, you need to disable all renders and respond_withs in the controller:

    RestfulJson.render_enabled = false

Or you can also just enable/disable rendering in a controller via setting `self.render_enabled`:

    self.render_enabled = false

Then make sure you add a JBuilder view for each action you require. Although all may not be relevant, we support: index, show, new, edit, create, update, destroy. Maybe you'd create:

    /app/views/plural_name_of_model/index.json.jbuilder
    /app/views/plural_name_of_model/show.json.jbuilder
    /app/views/plural_name_of_model/create.json.jbuilder
    /app/views/plural_name_of_model/update.json.jbuilder

See [Railscast #320][railscast320] for more examples on setting up and using JBuilder.

###### Other

You should be able to use anything that works with normal render/responds_with in Rails controllers that don't require any additional code in the action methods of the controller are ok, e.g. as_json defined in model, etc.

#### Create/Update JSON Request/Params Acceptance

##### Permitters

We include ApplicationPermitter and optional controller support for Adam Hawkins' [permitters][permitter].

The default setting is for permitters to be used:

    self.use_permitters = true

Permitters use [Cancan][cancan] for authorization and [Strong Parameters][strong_parameters] for parameter permitting.

We have an implementation of ApplicationPermitter, so you just need permitters in `/app/permitters/`, e.g. `/app/permitters/foobar_permitter.rb`:

    class FoobarPermitter < ApplicationPermitter
      # attributes we accept (the new way to do attr_accessible, OO-styley! Thanks, twinturbo)
      permit :id, :foo_id
      permit :bar_id
      permit :notes
      # foobar has accepts_nested_attributes_for :barfoos
      scope :barfoos_attributes do |barfoo|
        barfoo.permit :id, :favorite_color, :favorite_chicken
      end
    end

If you don't accept anything in create/update, you should have an empty Permitter for the model:

    class FoobarPermitter < ApplicationPermitter
    end

##### Strong Parameters

To use strong_parameters by themselves, without Permitters/Cancan, specify this in restful_json config/controller config:

    self.use_permitters = false

As noted in [Strong Parameters][strong_parameters], it is suggested to encapsulate the permitting into a private method in the controller, so we've taken that to heart and the controller just attempts to call the relevant *_params method or create_*_params/update_*_params, e.g. in the controller:

    def foobar_params
      params.require(:foobar).permit(:name, :age)
    end

##### Mass Assignment Security

To use mass assignment security in Rails 3.x, specify this in restful_json config/controller config:

    self.use_permitters = false

Don't use any of these, as they each include Strong Parameters:

    include ActionController::StrongParameters
    include RestfulJson::DefaultController
    acts_as_restful_json

Only the main controller is needed:

    include RestfulJson::Controller

Then, make sure that attr_accessible and/or attr_protected, etc. are used properly. 

### App-level Configuration

At the bottom of `config/environment.rb`, you can set config items one at a time like:

    RestfulJson.debug = true

or in bulk, like:

    RestfulJson.configure do
      
      # default for :using in can_filter_by
      self.can_filter_by_default_using = [:eq]
      
      # to output debugging info during request handling
      self.debug = false
      
      # delimiter for values in request parameter values
      self.filter_split = ','
      
      # equivalent to specifying respond_to :json, :html in the controller, and can be overriden in the controller. Note that by default responders gem sets respond_to :html in application_controller.rb.
      self.formats = :json, :html
      
      # default number of records to return if using the page request function
      self.number_of_records_in_a_page = 15
      
      # delimiter for ARel predicate in the request parameter name
      self.predicate_prefix = '!'
      
      # if true, will render resource and HTTP 201 for post/create or resource and HTTP 200 for put/update. ignored if render_enabled is false.
      self.return_resource = false
      
      # if false, controller actions will just set instance variable and return it instead of calling setting instance variable and then calling render/respond_with
      self.render_enabled = true
      
      # if false, will assume that it should either try calling create_(single model name)_params or fall back to calling (single model name)_params if create, or update_(single model name)_params then (single model name)_params if that didn't respond, if update. if it can't call those, it will either use mass assignment security, no parameter security, or some other solution, depending on how it is configured.
      self.use_permitters = true
      
    end

### Controller-specific Configuration

In the controller, you can set a variety of class attributes with `self.something = ...` in the body of your controller.

All of the app-level configuration parameters are configurable at the controller level:

      self.can_filter_by_default_using = [:eq]
      self.debug = false
      self.filter_split = ','
      self.formats = :json, :html
      self.number_of_records_in_a_page = 15
      self.predicate_prefix = '!'
      self.return_resource = false
      self.render_enabled = true
      self.use_permitters = true

In addition there are some that are controller-only...

If you don't use the standard controller naming convention, you can define this in the controller:

        self.model_class = YourModel

If it doesn't handle the other forms well, you can explicitly define the singular/plural names:

        self.model_singular_name = 'your_model'
        self.model_plural_name = 'your_models'

These are used for *_url method definitions, to set instance variables like `@foobar` and `@foobars` dynamically, etc.

Other class attributes are available for setting/overriding, but they are all set by the other class methods defined in the next section.

### Usage

You have a configurable generic Rails 3.1+/4+ controller that does the index, show, create, and update and other custom actions easily for you.

Everything is well-declared and fairly concise.

You can have something as simple as:

    class FoobarsController < ApplicationController
      include ServiceControllerAdditions
    end

which would use the restful_json configuration and the controller's classname for the service definition and provide a simple no-frills JSON CRUD controller that behaves mostly like a typical Rails controller created via scaffold.

Or, you could define more bells and whistles (read on to see what these do...):

    class FoobarsController < ApplicationController

      include ServiceControllerAdditions
      
      query_for :index, is: ->(t,q) {q.joins(:apples, :pears).where(apples: {color: 'green'}).where(pears: {color: 'green'})}
      
      # args sent to can_filter_by are the request parameter name(s)
      
      # implies using: [:eq] because RestfulJson.can_filter_by_default_using = [:eq]
      can_filter_by :foo_id
      
      # can specify multiple predicates and optionally a default value
      can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
      
      can_filter_by :a_request_param_name, with_query: ->(t,q,param_value) {q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value})}
      
      can_filter_by :and_another, through: [:some_attribute_on_this_model]
      
      can_filter_by :one_more, through: [:some_association, :some_attribute_on_some_association_model]
      
      can_filter_by :and_one_more, through: [:my_assoc, :my_assocs_assoc, :my_assocs_assocs_assoc, :an_attribute_on_my_assocs_assocs_assoc]
      
      supports_functions :count, :uniq, :take, :skip, :page, :page_count
      
      order_by {:foo_date => :asc}, :foo_color, {:bar_date => :desc} # an ordered array of hashes, assumes :asc if not a hash

      serialize_action :index, with: ListFoobarSerializer
      
      # comma-delimited if you want more than :json, e.g. :json, :html
      respond_to :json, :html
      
    end

#### Default Filtering by Attribute(s)

First, declare in the controller:

    can_filter_by :foo_id

If `RestfulJson.can_filter_by_default_using = [:eq]` as it is by default, then you can now get Foobars with a foo_id of '1':

    http://localhost:3000/foobars?foo_id=1

`can_filter_by` without an option means you can send in that request param (via routing or directly, just like normal in Rails) and it will use that in the ARel query (safe from SQL injection and only letting you do what you tell it). `:using` means you can use those [ARel][arel] predicates for filtering. If you do `Arel::Predications.public_instance_methods.sort` in Rails console, you can see a list of the available predicates. So, you could get crazy with:

    can_filter_by :does_not_match, :does_not_match_all, :does_not_match_any, :eq, :eq_all, :eq_any, :gt, :gt_all, :gt_any, :gteq, :gteq_all, :gteq_any, :in, :in_all, :in_any, :lt, :lt_all, :lt_any, :lteq, :lteq_all, :lteq_any, :matches, :matches_all, :matches_any, :not_eq, :not_eq_all, :not_eq_any, :not_in, :not_in_all, :not_in_any

`can_filter_by` can also specify a `:with_query` to provide a lambda that takes the request parameter in when it is provided by the request.

    can_filter_by :a_request_param_name, with_query: ->(t,q,param_value) {q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value})}

And `can_filter_by` can specify a `:through` to provide an easy way to inner join through a bunch of models using ActiveRecord relations, by specifying 0-to-many association names to go "through" to the final argument, which is the attribute name on the last model. The following is equivalent to the last query:

    can_filter_by :a_request_param_name, through: [:some_assoc, :some_attr]

Let's say you are in MagicalValleyController, and the MagicalValley model `has many :magical_unicorns`. The MagicalUnicorn model has an attribute called `name`. You want to return MagicalValleys that are associated with all of the MagicalUnicorns named 'Rainbow'. You could do either:

    can_filter_by :magical_unicorn_name, with_query: ->(t,q,param_value) {q.joins(:magical_unicorns).where(:magical_unicorns=>{name: param_value})}

or:

    can_filter_by :magical_unicorn_name, through: [:magical_unicorns, :name]

and you can then use this:

    http://localhost:3000/magical_valleys?magical_unicorn_name=Rainbow

or if a MagicalUnicorn `has_many :friends` and a MagicalUnicorn's friend has a name attribute:

    can_filter_by :magical_unicorn_friend_name, through: [:magical_unicorns, :friends, :name]

and use this to get valleys associated with unicorns who in turn have a friend named Oscar:

    http://localhost:3000/magical_valleys?magical_unicorn_friend_name=Oscar

#### Other Filters by Attribute(s)

First, declare in the controller:

    can_filter_by :seen_on, using: [:gteq, :eq_any]

Get Foobars with seen_on of 2012-08-08 or later using the [ARel][arel] gteq predicate splitting the request param on `predicate_prefix` (configurable), you'd use:

    http://localhost:3000/foobars?seen_on!gteq=2012-08-08

Multiple values are separated by `filter_split` (configurable):

    http://localhost:3000/foobars?seen_on!eq_any=2012-08-08,2012-09-09

#### Supported Functions

##### Declaring

`supports_functions` lets you allow the [ARel][arel] functions: `:uniq`, `:skip`, `:take`, and/or `:count`.

##### Unique (DISTINCT)

First, declare in the controller:

    supports_functions :uniq

To return a simple unique view of a model, combine use of an [ActiveModel Serializer][active_model_serializers] that returns just the attribute you want along with the uniq param, e.g. to return unique/distinct colors of foobars you'd have a serializer to just return the color and then use:

    http://localhost:3000/foobars?uniq=

##### Count

First, declare in the controller:

    supports_functions :count

This is another filter that can be used with the others, but instead of returning the json objects, it returns their count, which is useful for paging to determine how many results you can page through:

    http://localhost:3000/foobars?count=

##### Paging

In controller make sure these are included:

    supports_functions :page, :page_count

To get the first page of results:

    http://localhost:3000/foobars?page=1

To get the second page of results:

    http://localhost:3000/foobars?page=2

To get the total number of pages of results:

    http://localhost:3000/foobars?page_count=

To set page size at application level:

    RestfulJson.number_of_records_in_a_page = 15

To set page size at controller level:

    self.number_of_records_in_a_page = 15

For a better idea of how this works on the backend, look at [ARel][arel]'s skip and take, or see Variable Paging.

###### Skip and Take (OFFSET and LIMIT)

In controller make sure these are included:

    supports_functions :skip, :take

To skip rows returned, use 'skip'. It is called take, because skip is the [ARel][arel] equivalent of SQL OFFSET:

    http://localhost:3000/foobars?skip=5

To limit the number of rows returned, use 'take'. It is called take, because take is the [ARel][arel] equivalent of SQL LIMIT:

    http://localhost:3000/foobars.json?take=5

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

##### Custom Serializers

If using ActiveModel::Serializers, you can use something other than the (singular model name)Serializer via serialize_action:

    serialize_action :index, with: ListFoobarSerializer

The built-in actions that support custom serializers (you can add more) are: index, show, new, create, update, destroy, and any action you automatically have created via using the restful_json `query_for` method.

It will use `serialize` for single result actions like show, new, create, update, destroy, and `serialize_each` with index and custom actions.

To override, specify `for:` with `:array` or `:each`, e.g.:

    serialize_action :index, :some_custom_action, with: FoosSerializer, for: :array

And, you can just use the default serialization provided by AMS if you want. No class needed.

##### Custom Queries

To filter the list where the status_code attribute is 'green':

    # t is self.model_class.arel_table and q is self.model_class.scoped
    query_for :index, is: lambda {|t,q| q.where(:status_code => 'green')}

or use the `->` Ruby 1.9 lambda stab operator. You can also filter out items that have associations that don't have a certain attribute value (or anything else you can think up with [ARel][arel]/[ActiveRecord relations][ar]). To filter the list where the object's apples and pears associations are green:

    # t is self.model_class.arel_table and q is self.model_class.scoped
    # note: must be no space between -> and parenthesis
    query_for :index, is: ->(t,q) {
      q.joins(:apples, :pears)
      .where(apples: {color: 'green'})
      .where(pears: {color: 'green'})
    }

##### Define Custom Actions with Custom Queries

`query_for` also will `alias_method (some action), :index` anything other than `:index`, so you can easily create custom non-RESTful action methods:

    # t is self.model_class.arel_table and q is self.model_class.scoped
    # note: must be no space between -> and parenthesis in lambda syntax!
    query_for :some_action, is: ->(t,q) {q.where(:status_code => 'green')}

Note that it is a proc so you can really do whatever you want with it and will have access to other things in the environment or can call another method, etc.

You are still working with regular controllers here, so add or override methods if you want more!

### Routing

Respects regular and nested Rails resourceful routing and controller namespacing, e.g. in `config/routes.rb`:

    MyAwesomeApp::Application.routes.draw do
      namespace :my_service_controller_module do
        resources :foobars
        # why use nested if you only want to provide ways of querying via path
        match 'bars/:bar_id/foobars(.:format)' => 'foobars#index'
      end
    end

### With Rails-api

If you want to try out [rails-api][rails-api], maybe use:

    gem 'rails-api', '~> 0.0.3'

In `apps/controllers/restful_json_api.rb`:

    module RestfulJsonApi
      extend ActiveSupport::Concern

      included do
        # Rails-api lets you choose features. You might not need all of these, or may need others.
        include AbstractController::Translation
        include ActionController::HttpAuthentication::Basic::ControllerMethods
        include AbstractController::Layouts
        include ActionController::MimeResponds
        include ActionController::Cookies
        include ActionController::ParamsWrapper
        include RestfulJson::DefaultController

        # If you want any additional inline class stuff, it goes here...
      end
      
      module ClassMethods
        # Any additional class methods...
      end
      
      # Instance methods...
      
    end

    class FoobarsController < ActionController::API
      include RestfulJsonApi  
    end

    class BarfoosController < ActionController::API
      include RestfulJsonApi  
    end

Note that in `/config/initializers/wrap_parameters.rb` you might need to add `include ActionController::ParamsWrapper` prior to the `wrap_parameters` call. For example, for unwrapped JSON, it would look like:

    ActiveSupport.on_load(:action_controller) do
      # without include of ParamsWrapper, will get undefined method `wrap_parameters' for ActionController::API:Class (NoMethodError)
      include ActionController::ParamsWrapper
      # in this case it's expecting unwrapped params, but we could maybe use wrap_parameters format: [:json]
      wrap_parameters format: []
    end

    # Disable root element in JSON by default.
    ActiveSupport.on_load(:active_record) do
      self.include_root_in_json = false
    end

### Refactoring and Customing the Default Behavior

##### Parent/Ancestor Class Definition Not Supported

Don't do this:

    class ServiceController < ApplicationController
      include ::ActionController::Serialization
      include ::ActionController::StrongParameters
      include ::TwinTurbo::Controller
      include ::RestfulJson::Controller
    end
    
    # nor should you do this
    #class FoobarsController < ApplicationController
    #  include RestfulJson::DefaultController
    #end
    
    class FoobarsController < ServiceController
    end
    
    class BarfoosController < ServiceController
    end

It may appear to work when using the same controller or even on each new controller load, but when you make requests to BarfoosController, make a request to FoobarsController, and then make a request back to the BarfoosController, it may fail in very strange ways, such as missing column(s) from SQL results (because it isn't using the correct model).

Do as a module instead!

##### Customizing Behavior via Module

Remember how we created a `apps/controllers/service_controller_additions.rb`?

You can add behavior to it!

Let's add a method so that `hello :world` in the controller will make it return `{"hello": "world"}`:

    module HelloWorld
      extend ActiveSupport::Concern      
      included do
        # see notes in Service Controller Additions section of restful_json doc for what is needed
        include ::ActionController::Serialization
        include ::ActionController::StrongParameters
        include ::TwinTurbo::Controller
        include ::RestfulJson::Controller

        # let's add a name that can be set with a class method
        class_attribute :name, instance_writer: true
      end

      module ClassMethods
        def hello(value)
          self.name = value.to_sym
        end
      end

      def index
        respond_to do |format|
          format.json do
            render :json => {"hello" => self.name}.to_json
          end
        end
      end
    end

Then:

    class FoobarsController < ApplicationController
      include HelloWorld
      hello :world
    end

    class BarfoosController < ApplicationController
      include HelloWorld
      hello :world
    end

For more realistic use that takes advantage of existing configuration in the controller, take a look at the controller in `lib/restful_json/controller.rb` to see how the actions are defined, and just copy/paste into your controller or module, etc.

Make sure that the inclusion of your module is defined after `include RestfulJson::Controller`, `include RestfulJson::DefaultController`, or `acts_as_restful_json` is called.

### Release Notes

#### restful_json v3.3

In past versions, everything was done to the models whether you wanted it done or not. Have been trying to transition away from forcing anything, so starting with v3.3, ensure the following is done.

If you are using Rails 3.1-3.2 and want to use permitters or strong_parameters in all models:

Make sure you include Strong Parameters:

    gem "strong_parameters"

Include this in `config/environment.rb`:

    ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)

If you want to use permitters in all models, you need Cancan:

Make sure you include Cancan:

    gem "cancan"

Include this in `config/environment.rb`

    ActiveRecord::Base.send(:include, CanCan::ModelAdditions)

### Rails Version-specific Eccentricities

Strong Parameters is included in Rails 4. Rails 4.1 and up will need `gem 'activerecord-deprecated_finders' gem, at least for now. (At time of writing Rails 4.1 is not out yet, so not a problem.)

If you are using Rails 3.1, note that respond_with returns HTTP 200 instead of 204 for update and destroy, unless return_resource is true.

### Thanks!

Without our users, where would we be? Feedback, bug reports, and code/documentation contributions are always welcome!

### Contributors

* Gary Weaver (https://github.com/garysweaver)
* Tommy Odom (https://github.com/tpodom)

### License

Copyright (c) 2013 Gary S. Weaver, released under the [MIT license][lic].

[employee-training-tracker]: https://github.com/FineLinePrototyping/employee-training-tracker
[built_with_angularjs]: http://builtwith.angularjs.org/
[permitter]: http://broadcastingadam.com/2012/07/parameter_authorization_in_rails_apis/
[cancan]: https://github.com/ryanb/cancan
[strong_parameters]: https://github.com/rails/strong_parameters
[active_model_serializers]: https://github.com/josevalim/active_model_serializers
[authlogic]: https://github.com/binarylogic/authlogic
[devise]: https://github.com/plataformatec/devise
[arel]: https://github.com/rails/arel
[ar]: http://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[rails-api]: https://github.com/rails-api/rails-api
[railscast320]: http://railscasts.com/episodes/320-jbuilder
[lic]: http://github.com/rubyservices/restful_json/blob/master/LICENSE
