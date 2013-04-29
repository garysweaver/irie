[![Build Status](https://secure.travis-ci.org/rubyservices/restful_json.png?branch=master)](http://travis-ci.org/rubyservices/restful_json) [![Gem Version](https://badge.fury.io/rb/restful_json.png)](http://badge.fury.io/rb/restful_json)
# Restful JSON

Develop declarative, featureful JSON service controllers to use with modern Javascript MVC frameworks like AngularJS, Ember, etc. with much less code. It is RESTful-ish instead of RESTful, since it isn't hypermedia-driven, but it meets the long-standing Rails definition of being RESTful.

What does that mean? It means you typically won't have to write index, create, update, destroy, etc. methods in your controllers to filter, sort, and do complex queries.

Why do you need this if Rails controllers already make it easy to provide RESTful JSON services via generated controllers? Because this is just as flexible, almost as declarative, and takes less code. Your controllers will be easier to read, and there will be less code to maintain. When you need an action method more customized, that method is all you will have to write.

The goal of the project is to reduce service controller code in an intuitive way, not to be a be-everything DSL or limit what you can do in a controller. Choose what features to expose, and you can still define/redefine actions etc. at will.

We test with travis-ci with with Rails 3.1, 3.2, and Rails 4. Feel free to submit issues and/or do a pull requests if you run into anything.

You can use any of these for the JSON response (the view):
* [ActiveModel::Serializers][active_model_serializers]
* [JBuilder][jbuilder]
* Almost anything else that will work with render/respond_with without anything special in the controller action method implementation.

And can use any of the following for authorizing parameters in the incoming JSON (for create/update):
* [Permitters][permitters]
* [Strong Parameters][strong_parameters]
* Mass assignment security in Rails 3.x (attr_accessible, etc.).

An example app using an older version of restful_json with AngularJS is [employee-training-tracker][employee-training-tracker], featured in [Built with AngularJS][built_with_angularjs].

### Usage

You have a configurable generic Rails 3.1.x/3.2.x/4.0.x controller that does the index, show, create, and update and other custom actions easily for you.

Everything is well-declared and fairly concise.

You can have something as simple as:

```ruby
class FoobarsController < ApplicationController
  include RestfulJson::DefaultController
end
```

which would use the restful_json configuration and the controller's classname for the service definition and provide a simple no-frills JSON CRUD controller that behaves somewhat similarly to a Rails controller created via `rails g scaffold ...`.

Or, you can define many more bells and whistles with declarative ARel through HTTP(S):

```ruby
class FoobarsController < ApplicationController
  include RestfulJson::DefaultController

  query_for :index, is: ->(t,q) {q.joins(:apples, :pears).where(apples: {color: 'green'}).where(pears: {color: 'green'})}
  
  # use can_filter_by followed by the request parameter name(s)
  
  # implies using: [:eq] because RestfulJson.can_filter_by_default_using = [:eq]
  can_filter_by :foo_id
  
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
  
  can_filter_by :a_request_param_name, with_query: ->(t,q,param_value) {q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value})}
  
  can_filter_by :and_another, through: [:some_attribute_on_this_model]
  
  can_filter_by :one_more, through: [:some_association, :some_attribute_on_some_association_model]
  
  can_filter_by :and_one_more, through: [:my_assoc, :my_assocs_assoc, :my_assocs_assocs_assoc, :an_attribute_on_my_assocs_assocs_assoc]
  
  supports_functions :count, :uniq, :take, :skip, :page, :page_count
  
  order_by {:foo_date => :asc}, :foo_color, {:bar_date => :desc} # assumes :asc for foo_color, since hash not provided

  serialize_action :index, with: ListFoobarSerializer
  
  # optional. by default acts like Rails and will serve in json or html
  respond_to :json, :html
  
end
```

Now you can query like these:

```
https://example.org/foobars?foo_id=123
https://example.org/foobars?bar_date!gt=2012-08-08
https://example.org/foobars?bar_date!gt=2012-08-08&count=
https://example.org/foobars?and_one_more=an_attribute_value_on_my_assocs_assocs_assoc&uniq=
https://example.org/foobars?page_count=
https://example.org/foobars?page=1
https://example.org/foobars?skip=30&take=15
```

### Installation

In your Rails app's `Gemfile`:

```ruby
gem 'restful_json', '~> 4.0.0'
```

Then:

```
bundle install
```

#### Optional

##### Strong Parameters

[Strong Parameters][strong_parameters] is part of Rails 4, so *don't* include this gem if using Rails 4. However, if you are using Rails 3, it can be used on its own or as a dependency of Permitters:

```ruby
gem 'strong_parameters', '~> 0.2.0'
```

Be sure to read the [Strong Parameters][strong_parameters] docs, because you need to use `config.active_record.whitelist_attributes = false` in your app config, etc. if using Rails 3. Also, this removes the need for `attr_accessible` or `attr_protected` in your models, so convert those restrictions to either Permitters or Strong Parameters.  And you'll need `ActiveModel::ForbiddenAttributesProtection` included in your models.

As noted in [Strong Parameters][strong_parameters], it is suggested to encapsulate the permitting into a private method in the controller, so we allow:

```ruby
def foobar_params
  params.require(:foobar).permit(:name, :age)
end
```

or if `self.allow_action_specific_params_methods = true` is set in restful_json configuration, as it is by default:

```ruby
def create_foobar_params
  params.require(:foobar).permit(:name, :age)
end

def update_foobar_params
  params.require(:foobar).permit(:age)
end
```

and even other actions if you want:

```ruby
def index_foobars_params
  params.require(:foobars).permit(:foo_id)
end

# where 'some_action' is a custom action created by query_for
def some_action_foobars_params
  params.require(:foobars).permit(:foo_id)
end

def show_foobar_params
  params.require(:foobar).permit(:id)
end
```

##### Permitters

[Permitters][permitters] can use Strong Parameters and CanCan or another authorization solution for parameter authorization:

```ruby
gem 'permitters', '~> 0.0.1'
```

The default restful_json configuration is for only create and update actions to use permitters:

```ruby
self.actions_that_permit = [:create, :update]
```

Read the [Permitters][permitters] documentation for more info on how you can encapsulate and easily share permittance and authorization.

##### CanCan

[CanCan][cancan] can be used via Permitters or on its own:

```ruby
gem 'cancan', '~> 1.6.9'
```

And [CanCan][cancan] supports [Authlogic][authlogic], [Devise][devise], etc. for authentication. See the [CanCan][cancan] docs for more info.

The default restful_json configuration is for `authorize!(permission, model)` to be called for create and update:

```ruby
self.actions_that_authorize = [:create, :update]
```

So, for example, when a create is attempted, it will first call `authorize!(:create, Foobar)`.

`CanCan::ModelAdditions` needs to be included on any model that you plan to use CanCan with, per the CanCan documentation.

##### JBuilder

[JBuilder][jbuilder] comes with Rails 4, or can be included in Rails 3 to provide JSON views. See [Railscast #320][railscast320] for more info on using JBuilder:

```ruby
gem 'jbuilder', '~> 1.3.0'
```

If you want to enable JBuilder for all restful_json services, you may want to disable all renders and respond_withs in the controller:

```ruby
RestfulJson.render_enabled = false
```

##### ActiveModel::Serializers

[ActiveModel::Serializers][active_model_serializers] is great for specifying what should go into the JSON responses as an alternative to JBuilder, and restful_json provides a `serialize_action` method to specify custom serializer if you don't want to use the default, e.g. `serialize_action :index, with: BarsSerializer` and `serialize_action :index, :my_other_list_action, with: BarsSerializer`.

```ruby
gem 'active_model_serializers', '~> 0.7.0'
```

Because of some issues with some versions of ActiveModel::Serializers using respond_with, you might want to set the option:

```ruby
RestfulJson.avoid_respond_with = true
```

##### Mass Assignment Security

To use mass assignment security in Rails 3.x, specify this in restful_json config/controller config:

```ruby
self.use_permitters = false
```

Don't use any of these, as they each include Strong Parameters:

```ruby
include ActionController::StrongParameters
include RestfulJson::DefaultController
```

Only the main controller is needed:

```ruby
include RestfulJson::Controller
```

Then, make sure that attr_accessible and/or attr_protected, etc. are used properly. 

##### Other Options

You should be able to use anything that works with normal render/responds_with in Rails controllers without additional code in the controller. If you'd like to use something that requires additional code in the action methods of the controller, and you think it would be a good fit, feel free to do a pull request.

### Application Configuration

At the bottom of `config/environment.rb`, you can set restful_json can be configured one line at a time.

```ruby
RestfulJson.debug = true
```

or in bulk, like:

```ruby
RestfulJson.configure do

  # default for :using in can_filter_by
  self.can_filter_by_default_using = [:eq]

  # to log debug info during request handling
  self.debug = false

  # delimiter for values in request parameter values
  self.filter_split = ','.freeze

  # equivalent to specifying respond_to :json, :html in the controller, and can be overriden in the controller. Note that by default responders gem sets respond_to :html in application_controller.rb.
  self.formats = :json, :html

  # default number of records to return if using the page request function
  self.number_of_records_in_a_page = 15

  # delimiter for ARel predicate in the request parameter name
  self.predicate_prefix = '!'.freeze

  # if true, will render resource and HTTP 201 for post/create or resource and HTTP 200 for put/update. ignored if render_enabled is false.
  self.return_resource = false

  # if false, controller actions will just set instance variable and return it instead of calling setting instance variable and then calling render/respond_with
  self.render_enabled = true

  # use Permitters
  self.use_permitters = true

  # instead of using Rails default respond_with, explicitly define render in respond_with block
  self.avoid_respond_with = true

  # use the permitter_class for create and update, if use_permitters = true
  self.action_to_permitter = {create: nil, update: nil}

  # the methods that call authorize! action_sym, @model_class
  self.actions_that_authorize = [:create, :update]
  
  # if not using permitters, will check respond_to?("(action)_(plural_or_singular_model_name)_params".to_sym) and if true will __send__(method)
  self.allow_action_specific_params_methods = true
  
  # if not using permitters, will check respond_to?("(singular_model_name)_params".to_sym) and if true will __send__(method)
  self.actions_that_permit = [:create, :update]

  # in error JSON, break out the exception info into fields for debugging
  self.return_error_data = true

  # the class that is rescued in each action method, but if nil will always reraise and not handle
  self.rescue_class = StandardError
  
  # will define order of errors handled and what status and/or i18n message key to use
  self.rescue_handlers = []

  # rescue_handlers are an ordered array of handlers to handle rescue of self.rescue_class or sub types.
  # can use optional i18n_key for message, but will default to e.message if i18n_key not found.

  # support 404 error for ActiveRecord::RecordNotFound if using ActiveRecord.
  begin
    require 'active_record/errors'
    self.rescue_handlers << {exception_classes: [ActiveRecord::RecordNotFound], status: :not_found, i18n_key: 'api.not_found'.freeze}
  rescue LoadError, NameError
  end

  # support 403 error for CanCan::AccessDenied if using CanCan
  begin
    require 'cancan/exceptions'
    self.rescue_handlers << {exception_classes: [CanCan::AccessDenied], status: :forbidden, i18n_key: 'api.not_found'.freeze}
  rescue LoadError, NameError
  end

  # support 500 error for everything else that is a self.rescue_class (in action)
  self.rescue_handlers << {status: :internal_server_error, i18n_key: 'api.internal_server_error'.freeze}

end
```

### Controller Configuration

In the controller, you can set a variety of class attributes with `self.something = ...` in the body of your controller.

All of the app-level configuration parameters are configurable at the controller level:

```ruby
  self.can_filter_by_default_using = [:eq]
  self.debug = false
  self.filter_split = ','.freeze
  self.formats = :json, :html
  self.number_of_records_in_a_page = 15
  self.predicate_prefix = '!'.freeze
  self.return_resource = false
  self.render_enabled = true
  self.use_permitters = true
  self.avoid_respond_with = true
  self.return_error_data = true
  self.rescue_class = StandardError
  self.action_to_permitter = {create: nil, update: nil}
  self.actions_that_authorize = [:create, :update]
  self.allow_action_specific_params_methods = true
  self.actions_that_permit = [:create, :update]
  
  require 'active_record/errors'
  require 'cancan/exceptions'
  self.rescue_handlers [
    {exception_classes: [ActiveRecord::RecordNotFound], status: :not_found, i18n_key: 'api.not_found'.freeze},
    {exception_classes: [CanCan::AccessDenied], status: :forbidden, i18n_key: 'api.not_found'.freeze},
    {status: :internal_server_error, i18n_key: 'api.internal_server_error'.freeze}
  ]
```

In addition there are some that are controller-only...

If you don't use the standard controller naming convention, you can define this in the controller:

```ruby
self.model_class = YourModel
```

If it doesn't handle the other forms well, you can explicitly define the singular/plural names:

```ruby
self.model_singular_name = 'your_model'
self.model_plural_name = 'your_models'
```

These are used for *_url method definitions, to set instance variables like `@foobar` and `@foobars` dynamically, etc.

Other class attributes are available for setting/overriding, but they are all set by the other class methods defined in the next section.

#### Routing

You can just add normal Rails RESTful routes in `config/routes.rb`, e.g. for the Foobar model:

```ruby
MyAppName::Application.routes.draw do
  resources :foobars
end
```

Supports static, nested, etc. routes also, e.g.:

```ruby
MyAppName::Application.routes.draw do
  namespace :my_service_controller_module do
    resources :foobars
  end
end
```

Can pass in params from the path for use in filters, etc. as if they were request parameters:

```ruby
MyAppName::Application.routes.draw do
  namespace :my_service_controller_module do
    match 'bar/:bar_id/foobars(.:format)' => 'foobars#index'
  end
end    
```

#### Default Filtering by Attribute(s)

First, declare in the controller:

```ruby
can_filter_by :foo_id
```

If `RestfulJson.can_filter_by_default_using = [:eq]` as it is by default, then you can now get Foobars with a foo_id of '1':

```
http://localhost:3000/foobars?foo_id=1
```

`can_filter_by` without an option means you can send in that request param (via routing or directly, just like normal in Rails) and it will use that in the ARel query (safe from SQL injection and only letting you do what you tell it). `:using` means you can use those [ARel][arel] predicates for filtering. If you do `Arel::Predications.public_instance_methods.sort` in Rails console, you can see a list of the available predicates. So, you could get crazy with:

```ruby
can_filter_by :does_not_match, :does_not_match_all, :does_not_match_any, :eq, :eq_all, :eq_any, :gt, :gt_all, :gt_any, :gteq, :gteq_all, :gteq_any, :in, :in_all, :in_any, :lt, :lt_all, :lt_any, :lteq, :lteq_all, :lteq_any, :matches, :matches_all, :matches_any, :not_eq, :not_eq_all, :not_eq_any, :not_in, :not_in_all, :not_in_any
```

`can_filter_by` can also specify a `:with_query` to provide a lambda that takes the request parameter in when it is provided by the request.

```ruby
can_filter_by :a_request_param_name, with_query: ->(t,q,param_value) {q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value})}
```

And `can_filter_by` can specify a `:through` to provide an easy way to inner join through a bunch of models using ActiveRecord relations, by specifying 0-to-many association names to go "through" to the final argument, which is the attribute name on the last model. The following is equivalent to the last query:

```ruby
can_filter_by :a_request_param_name, through: [:some_assoc, :some_attr]
```

Let's say you are in MagicalValleyController, and the MagicalValley model `has many :magical_unicorns`. The MagicalUnicorn model has an attribute called `name`. You want to return MagicalValleys that are associated with all of the MagicalUnicorns named 'Rainbow'. You could do either:

```ruby
can_filter_by :magical_unicorn_name, with_query: ->(t,q,param_value) {q.joins(:magical_unicorns).where(:magical_unicorns=>{name: param_value})}
```

or:

```ruby
can_filter_by :magical_unicorn_name, through: [:magical_unicorns, :name]
```

and you can then use this:

```
http://localhost:3000/magical_valleys?magical_unicorn_name=Rainbow
```

or if a MagicalUnicorn `has_many :friends` and a MagicalUnicorn's friend has a name attribute:

```ruby
can_filter_by :magical_unicorn_friend_name, through: [:magical_unicorns, :friends, :name]
```

and use this to get valleys associated with unicorns who in turn have a friend named Oscar:

```
http://localhost:3000/magical_valleys?magical_unicorn_friend_name=Oscar
```

#### Other Filters by Attribute(s)

First, declare in the controller:

```ruby
can_filter_by :seen_on, using: [:gteq, :eq_any]
```

Get Foobars with seen_on of 2012-08-08 or later using the [ARel][arel] gteq predicate splitting the request param on `predicate_prefix` (configurable), you'd use:

```
http://localhost:3000/foobars?seen_on!gteq=2012-08-08
```

Multiple values are separated by `filter_split` (configurable):

```
http://localhost:3000/foobars?seen_on!eq_any=2012-08-08,2012-09-09
```

#### Supported Functions

##### Declaring

`supports_functions` lets you allow the [ARel][arel] functions: `:uniq`, `:skip`, `:take`, and/or `:count`.

##### Unique (DISTINCT)

First, declare in the controller:

```ruby
supports_functions :uniq
```

Now this works:

```
http://localhost:3000/foobars?uniq=
```

##### Count

First, declare in the controller:

```ruby
supports_functions :count
```

Now this works:

```
http://localhost:3000/foobars?count=
```

##### Paging

First, declare in the controller:

```ruby
supports_functions :page, :page_count
```

Now you can get the page count:

```
http://localhost:3000/foobars?page_count=
```

And access each page of results:

```
http://localhost:3000/foobars?page=1
http://localhost:3000/foobars?page=2
```

To set page size at application level:

```ruby
RestfulJson.number_of_records_in_a_page = 15
```

To set page size at controller level:

```ruby
self.number_of_records_in_a_page = 15
```

##### Skip and Take (OFFSET and LIMIT)

First, declare in the controller:

```ruby
supports_functions :skip, :take
```

To skip rows returned, use 'skip'. It is called take, because skip is the [ARel][arel] equivalent of SQL OFFSET:

```
http://localhost:3000/foobars?skip=5
```

To limit the number of rows returned, use 'take'. It is called take, because take is the [ARel][arel] equivalent of SQL LIMIT:

```
http://localhost:3000/foobars.json?take=5
```

Combine skip and take for manual completely customized paging, e.g.

```
http://localhost:3000/foobars?take=15
http://localhost:3000/foobars?skip=15&take=15
http://localhost:3000/foobars?skip=30&take=15
```

##### Custom Queries

To filter the list where the status_code attribute is 'green':

```ruby
# t is self.model_class.arel_table and q is self.model_class.scoped
query_for :index, is: lambda {|t,q| q.where(:status_code => 'green')}
```

or use the `->` Ruby 1.9 lambda stab operator (note lack of whitespace between stab and parenthesis):

```ruby
# t is self.model_class.arel_table and q is self.model_class.scoped
query_for :index, is: is: ->(t,q) {q.where(:status_code => 'green')}
```

You can also filter out items that have associations that don't have a certain attribute value (or anything else you can think up with [ARel][arel]/[ActiveRecord relations][ar]), e.g. to filter the list where the object's apples and pears associations are green:

```ruby
# t is self.model_class.arel_table and q is self.model_class.scoped
# note: must be no space between -> and parenthesis
query_for :index, is: ->(t,q) {
  q.joins(:apples, :pears)
  .where(apples: {color: 'green'})
  .where(pears: {color: 'green'})
}
```

##### Define Custom Actions with Custom Queries

You are still working with regular controllers here, so add or override methods if you want more!

However `query_for` will create new action methods, so you can easily create custom non-RESTful action methods:

```ruby
# t is self.model_class.arel_table and q is self.model_class.scoped
# note: must be no space between -> and parenthesis in lambda syntax!
query_for :some_action, is: ->(t,q) {q.where(:status_code => 'green')}
```

Note that it is a proc so you can really do whatever you want with it and will have access to other things in the environment or can call another method, etc.

```ruby
query_for :some_action, is: ->(t,q) do
    if @current_user.admin?
      Rails.logger.debug("Notice: unfiltered results provided to admin #{@current_user.name}")
      # just make sure the relation is returned!
      q
    else
      q.where(:access => 'public')
    end        
end
```

Be sure to add a route for that action, e.g. in `config/routes.rb`, e.g. for the Barfoo model:

```ruby
MyAppName::Application.routes.draw do
  resources :barfoos do
    get 'some_action', :on => :collection
  end
end
```

##### Custom Serializers

If using ActiveModel::Serializers, you can use something other than the `(singular model name)Serializer` via `serialize_action`:

```ruby
serialize_action :index, with: ListFoobarSerializer
```

The built-in actions that support custom serializers (you can add more) are: index, show, new, create, update, destroy, and any action you automatically have created via using the restful_json `query_for` method.

It will use the `serializer` option for single result actions like show, new, create, update, destroy, and the `each_serializer` option with index and custom actions. Or, you can specify `for:` with `:array` or `:each`, e.g.:

```ruby
serialize_action :index, :some_custom_action, with: FoosSerializer, for: :array
```

Or, you could just use the default serialization, if you want.

##### Custom Permitters

If using Permitters, you can use something other than the `(singular model name)Permitter` via `permit_action`:

```ruby
permit_action :index, with: ListFoobarPermitter
```

The built-in actions that support custom permitters (you can add more) are: index, show, new, create, update, destroy, and any action you automatically have created via using the restful_json `query_for` method.

The default configuration specifies permitter as `nil` which indicates the default of `(singular model name)Permitter`:

```ruby
self.action_to_permitter = {create: nil, update: nil}
```

By using that app or controller config parameter, you can define default permitter classes for other actions that restful_json manages if you wish.

##### Strong Parameters Params Methods

Strong Parameters documentation suggests encapsulating permitting into a private method in the controller. We make this suggestion a convention to make development easier.

By convention, a restful_json controller can call the `(singular model name)_params` method for create and update actions. This is configured via:

```ruby
self.actions_supporting_params_methods = [:create, :update]
```

And by default restful_json allows action specific `(action)_(model)_params` methods, so you only need to define a method like `create_foobar_params` and it will try to call that on create:

```ruby
self.allow_action_specific_params_methods = true
```

### With Rails-api

If you want to try out [rails-api][rails-api]:

```ruby
gem 'rails-api', '~> 0.0.3'
```

In `app/controllers/my_service_controller.rb`:

```ruby
module MyServiceController
  extend ActiveSupport::Concern
  
  included do
    # Rails-api lets you choose features. You might not need all of these, or may need others.
    include AbstractController::Translation
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include AbstractController::Layouts
    include ActionController::MimeResponds
    include ActionController::Cookies
    include ActionController::ParamsWrapper

    # use Permitters and AMS
    include RestfulJson::DefaultController
    # or comment that last line and uncomment whatever you want to use
    #include ::ActionController::Serialization # AMS
    #include ::ActionController::StrongParameters
    #include ::TwinTurbo::Controller # Permitters which uses CanCan and Strong Parameters
    #include ::RestfulJson::Controller

    # If you want any additional inline class stuff, it goes here...
  end      
end

class FoobarsController < ActionController::API
  include MyServiceController  
end

class BarfoosController < ActionController::API
  include MyServiceController  
end
```

Note that in `/config/initializers/wrap_parameters.rb` you might need to add `include ActionController::ParamsWrapper` prior to the `wrap_parameters` call. For example, for unwrapped JSON, it would look like:

```ruby
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
```

### Refactoring and Customing the Default Behavior

##### Parent/Ancestor Class Definition Not Supported

Don't subclass and include in the parent, that puts the class attributes into the parent which means they would be shared by the children and bad things can happen.

Don't do this:

```ruby
class ServiceController < ApplicationController
  include ::ActionController::Serialization
  include ::ActionController::StrongParameters
  include ::TwinTurbo::Controller
  include ::RestfulJson::Controller
end

class FoobarsController < ServiceController
end

class BarfoosController < ServiceController
end
```

And don't do this:

```ruby
class FoobarsController < ApplicationController
  include RestfulJson::DefaultController
end

class FoobarsController < ServiceController
end

class BarfoosController < ServiceController
end
```

It may appear to work when using the same controller or even on each new controller load, but when you make requests to BarfoosController, make a request to FoobarsController, and then make a request back to the BarfoosController, it may fail in very strange ways, such as missing column(s) from SQL results (because it isn't using the correct model).

##### Customizing Behavior via Patch

In `config/initializers/restful_json.rb` you can monkey patch the RestfulJson::Controller module. The DefaultController includes that, so it will get your changes also:

```ruby
module RestfulJson
  module Controller
    
    # class methods that should be implemented or overriden go in ClassMethods

    module ClassMethods
      def hello(name)
        class_attribute :name, instance_writer: true
        self.name = name        
      end
    end

    # instance methods that should be implemented or overriden.

    def index
      render :json => {:hello => self.name}
    end

  end
end
```

Now in your controller, if you:

```ruby
class FoobarsController < ApplicationController
  include RestfulJson::DefaultController
  hello 'world'
end
```

RestfulJson::DefaultController includes RestfulJson::Controller, which you patched, so when you call:

```
http://localhost:3000/foobars
```

You would get the response:

```
{'hello': 'world'}
```

For more realistic use that takes advantage of existing configuration in the controller, take a look at the controller in `lib/restful_json/controller.rb` to see how the actions are defined, and just copy/paste into your controller or module, etc. and modify as needed.

### Error Handling

#### Properly Handling Non-controller-action Errors

Some things restful_json can't do in the controller, like responding with json for a json request when the route is not setup correctly or an action is missing.

Rails 4 has basic error handling for non-HTML formats defined in the [public_exceptions][public_exceptions] and [show_exceptions][show_exceptions] Rack middleware.

Rails 3.2.x has support for `config.exceptions_app` which can be defined as the following to simulate Rails 4 exception handling:

```ruby
config.exceptions_app = lambda do |env|
  exception = env["action_dispatch.exception"]
  status = env["PATH_INFO"][1..-1]
  request = ActionDispatch::Request.new(env)
  content_type = request.formats.first
  body = { :status => status, :error => exception.message }
  format = content_type && "to_#{content_type.to_sym}"
  if format && body.respond_to?(format)
    formatted_body = body.public_send(format)
    [status, {'Content-Type' => "#{content_type}; charset=#{ActionDispatch::Response.default_charset}",
            'Content-Length' => body.bytesize.to_s}, [formatted_body]]
  else
    found = false
    path = "#{public_path}/#{status}.#{I18n.locale}.html" if I18n.locale
    path = "#{public_path}/#{status}.html" unless path && (found = File.exist?(path))

    if found || File.exist?(path)
      [status, {'Content-Type' => "text/html; charset=#{ActionDispatch::Response.default_charset}",
              'Content-Length' => body.bytesize.to_s}, [File.read(path)]]
    else
      [404, { "X-Cascade" => "pass" }, []]
    end
  end
end
```

That is just a collapsed version of the behavior of [public_exceptions][public_exceptions] as of April 2013, pre-Rails 4.0.0, so please look at the latest version and adjust accordingly. Use at your own risk, obviously.

Unfortunately, this doesn't work for Rails 3.1.x. However, in many scenarios there is the chance at a rare situation when the proper format is not returned to the client, even if everything is controlled as much as possible on the server. So, the client really needs to be able to handle such a case of unexpected format with a generic error.

But, if you can make Rack respond a little better for some errors, that's great.

To let all errors and exceptions fall out of restful_json action methods so that they will all be handled (without `error_data` in response) in the same way as routing, missing action, and other errors caught by Rack, just use:

```ruby
  RestfulJson.configure do
    self.rescue_handlers = []
  end
```

#### Controller Error-handling Configuration

The default configuration will rescue StandardError in each action method and will render as 404 for ActiveRecord::RecordNotFound or 500 for all other StandardError (and ancestors, like a normal rescue).

There are a few options to customize the rescue and error rendering behavior.

The `rescue_class` config option specifies what to rescue. Set to StandardError to behave like a normal rescue. Set to nil to just reraise everything rescued (to disable handling).

The `rescue_handlers` config option is like a minimalist set of rescue blocks that apply to every action method. For example, the following would effectively `rescue => e` (rescuing `StandardError`) and then for `ActiveRecord::RecordNotFound`, it would uses response status `:not_found` (HTTP 404). Otherwise it uses status `:internal_server_error` (HTTP 500). In both cases the error message is `e.message`:

```ruby
RestfulJson.configure do
  self.rescue_class = StandardError
  self.rescue_handlers = [
    {exception_classes: [ActiveRecord::RecordNotFound], status: :not_found},
    {status: :internal_server_error}
  ]
end
```

In a slightly more complicated case, this configuration would catch all exceptions raised with each actinon method that had `ActiveRecord::RecordNotFound` as an ancestor and use the error message defined by i18n key 'api.not_found'. All other exceptions would use status `:internal_server_error` (because it is a default, and doesn't have to be specified) but would use the error message defined by i18n key 'api.internal_server_error':

```ruby
RestfulJson.configure do
  self.rescue_class = Exception
  self.rescue_handlers = [
    {exception_ancestor_classes: [ActiveRecord::RecordNotFound], status: :not_found, i18n_key: 'api.not_found'.freeze},
    {i18n_key: 'api.internal_server_error'.freeze}
  ]
end
```

The `return_error_data` config option will not only return a response with `status` and `error` but also an `error_data` containing the `e.class.name`, `e.message`, and cleaned `e.backtrace`.

If you want to rescue using `rescue_from` in a controller or ApplicationController, let all errors and exceptions fall out of restful_json action methods with:

```ruby
RestfulJson.configure do
  self.rescue_handlers = []
end
```

### Release Notes

See the [changelog][changelog] for basically what happened when, and git log for everything else.

### Upgrading

The class method:

```ruby
acts_as_restful_json
```

Which depended on [Permitters][permitters] for Rails 3.x can be replaced with:

```ruby
include RestfulJson::DefaultController
```

or if using Rails 4.x, you should consider including the modules separately so that you don't include the `ActionController::StrongParameters` module twice in a controller, for example.

Also, in past versions, everything was done to the models whether you wanted it done or not. Have been trying to transition away from forcing anything, so starting with v3.3, ensure the following is done.

If you are using Rails 3.1-3.2 and want to use Permitters or Strong Parameters in all models:

Make sure you include Strong Parameters:

```ruby
gem "strong_parameters"
```

Include this in `config/environment.rb`:

```ruby
ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)
```

If you want to use Permitters in all models, you need CanCan:

Make sure you include CanCan:

```ruby
gem "cancan"
```

Include this in `config/environment.rb`

```ruby
ActiveRecord::Base.send(:include, CanCan::ModelAdditions)
```

Configuration, suggestions, and what to use and how may continue to change, but read this doc fully and hopefully it is correct!

### Rails Version-specific Eccentricities

Strong Parameters and JBuilder are included in Rails 4. You can use Permitters and ActiveModel::Serializers but for Permitters, you shouldn't define `gem 'strong_parameters'`.

If you are using Rails 3.1.x, note that respond_with returns HTTP 200 instead of 204 for update and destroy, unless return_resource is true.

### Contributing

Please fork, make changes in a separate branch, and do a pull request for your branch. Thanks!

### Contributors

* Gary Weaver (https://github.com/garysweaver)
* Tommy Odom (https://github.com/tpodom)

### License

Copyright (c) 2013 Gary S. Weaver, released under the [MIT license][lic].

[employee-training-tracker]: https://github.com/FineLinePrototyping/employee-training-tracker
[built_with_angularjs]: http://builtwith.angularjs.org/
[permitters]: https://github.com/permitters/permitters
[jbuilder]: https://github.com/rails/jbuilder
[cancan]: https://github.com/ryanb/cancan
[strong_parameters]: https://github.com/rails/strong_parameters
[active_model_serializers]: https://github.com/josevalim/active_model_serializers
[authlogic]: https://github.com/binarylogic/authlogic
[devise]: https://github.com/plataformatec/devise
[arel]: https://github.com/rails/arel
[ar]: http://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[rails-api]: https://github.com/rails-api/rails-api
[railscast320]: http://railscasts.com/episodes/320-jbuilder
[public_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/public_exceptions.rb
[show_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/show_exceptions.rb
[changelog]: https://github.com/rubyservices/restful_json/blob/master/CHANGELOG.md
[lic]: http://github.com/rubyservices/restful_json/blob/master/LICENSE
