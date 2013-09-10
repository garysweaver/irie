[![Build Status](https://secure.travis-ci.org/rubyservices/restful_json.png?branch=master)][travis] [![Gem Version](https://badge.fury.io/rb/restful_json.png)][badgefury]

# restful_json

In Rails 4, using `include RestfulJson::Controller` implements standard Rails actions in a conventional way to reduce the code you have to write, e.g. the following implements index, show, create, update, and destroy actions, so that you only have to write the views:

```ruby
class FoobarsController < ApplicationController
  # add standard Rails action methods
  include RestfulJson::Controller

  # standard Rails 4 respond_to
  respond_to :json, :html

private
  # standard Rails 4 request params permittance
  def foobar_params
    params.require(:foobar).permit(:name)
  end
end
```

Often the index action contains code to filter, order, etc. to reduce the amount of data retrieved for the client. Server-side pagination or chunking may be required for larger datasets. So, we support most things you would need to do. It should not allow an ability unless you specifically declare it:

```ruby
class FoobarsController < ApplicationController
  include RestfulJson::Controller
  respond_to :json, :html

  query_for index: ->(q) { q.joins(:apples, :pears).where(apples: {color: 'green'}).where(pears: {color: 'green'}) }
  can_filter_by :name
  default_filter_by :name, eq: 'anonymous'
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt]
  can_filter_by :some_attribute, through: [:assoc_name, :sub_assoc_name, :some_attribute]
  supports_functions :count, :distinct, :limit, :offset, :page, :page_count
  can_order_by :foo_date, :foo_color
  default_order_by {:foo_date => :asc}, :foo_color, {:bar_date => :desc}
end
```

Now assuming you set up routes and views, you could gets a Foobar with the name 'apple':

```
https://example.org/foobars?name=apple
```

Get records with bar_date > 2012-08-08:

```
https://example.org/foobars?bar_date.gt=2012-08-08
```

Count records with bar_date > 2012-08-08:

```
https://example.org/foobars?bar_date.gt=2012-08-08&count=
```

Filter by assoc_name.sub_assoc_name.some_attribute:

```
https://example.org/foobars?some_attribute=123&distinct=
```

Find out how many pages of results there are:

```
https://example.org/foobars?page_count=
```

Get the first page:

```
https://example.org/foobars?page=1
```

Get a custom page:

```
https://example.org/foobars?offset=30&limit=15
```

Change the sort to ascending by foo_color (asc) and foo_date (desc):

```
https://example.org/foobars?order=foo_color,-foo_date
```

Define an action with a lambda:

```ruby
query_for index: ->(q) { q.joins(:apples, :pears).where(apples: {color: 'green'}).where(pears: {color: 'green'}) }
```

or filter by a request param with a lambda:

```ruby
can_filter_by_query a_request_param_name: ->(q, param_value) { q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value}) }
```

### Installation

In your Rails app's `Gemfile`:

```ruby
gem 'restful_json' # use ~> and set to latest version
```

Then:

```
bundle install
```

### Application Configuration

The default config may be fine, but you can customize it.

Each application-level configuration option can be configured one line at a time:

```ruby
RestfulJson.number_of_records_in_a_page = 30
```

or in bulk, like:

```ruby
RestfulJson.configure do
  
  # Default for :using in can_filter_by.
  self.can_filter_by_default_using = [:eq]
  
  # Delimiter for values in request parameter values.
  self.filter_split = ','

  # Use one or more alternate request parameter names for functions,
  # e.g. use very_distinct instead of distinct, and either limit or limita for limit
  #   self.function_param_names = {distinct: :very_distinct, limit: [:limit, :limita]}
  # Supported_functions in the controller will still expect the original name, e.g. distinct.
  self.function_param_names = {}
  
  # Delimiter for ARel predicate in the request parameter name.
  self.predicate_prefix = '.'
  
  # Default number of records to return if using the page request function.
  self.number_of_records_in_a_page = 15
  
end
```

You may want to put any configuration in an initializer like `config/initializers/restful_json.rb`.

### Controller Configuration

The default controller config may be fine, but you can customize it.

In the controller, you can set a variety of class attributes with `self.something = ...` in the body of your controller.

All of the app-level configuration parameters are configurable in the controller class body:

```ruby
  # Default for :using in can_filter_by.
  self.can_filter_by_default_using = [:eq]
  
  # Delimiter for values in request parameter values.
  self.filter_split = ','

  # Use one or more alternate request parameter names for functions,
  # e.g. use very_distinct instead of distinct, and either limit or limita for limit
  #   self.function_param_names = {distinct: :very_distinct, limit: [:limit, :limita]}
  # Supported_functions in the controller will still expect the original name, e.g. distinct.
  self.function_param_names = {}
  
  # Delimiter for ARel predicate in the request parameter name.
  self.predicate_prefix = '.'
  
  # Default number of records to return if using the page request function.
  self.number_of_records_in_a_page = 15
```

Controller-only config options:

```ruby
self.model_class = YourModel
self.model_singular_name = 'your_model'
self.model_plural_name = 'your_models'
```

#### Filtering by Attribute(s)

First, declare in the controller:

```ruby
can_filter_by :foo_id # allows http://localhost:3000/foobars?foo_id=1
```

If `RestfulJson.can_filter_by_default_using = [:eq]` as it is by default, then you can now get Foobars with a foo_id of '1':

```
http://localhost:3000/foobars?foo_id=1
```

`can_filter_by` without an option means you can send in that request param (via routing or directly), and it will use that in the ARel query (safe from SQL injection and only letting you do what you tell it).

`:using` means you can use those [ARel][arel] predicates for filtering:

```ruby
can_filter_by :seen_on, using: [:gteq, :eq_any]
```

By appending the predicate prefix (`.` by default) to the request parameter name, you can use any [ARel][arel] predicate you allowed, e.g.:

```
http://localhost:3000/foobars?seen_on.gteq=2012-08-08
```

If you do `Arel::Predications.public_instance_methods.sort` in Rails console, you can see a list of the available predicates. So, you could get crazy with:

```ruby
can_filter_by :does_not_match, :does_not_match_all, :does_not_match_any, :eq, :eq_all, :eq_any, :gt, :gt_all, :gt_any, :gteq, :gteq_all, :gteq_any, :in, :in_all, :in_any, :lt, :lt_all, :lt_any, :lteq, :lteq_all, :lteq_any, :matches, :matches_all, :matches_any, :not_eq, :not_eq_all, :not_eq_any, :not_in, :not_in_all, :not_in_any
```

And `can_filter_by` can specify a `:through` to provide an easy way to inner join through a bunch of models using ActiveRecord relations, by specifying 0-to-many association names to go "through" to the final argument, which is the attribute name on the last model. The following is equivalent to the last query:

```ruby
can_filter_by :a_request_param_name, through: [:some_assoc, :some_attr]
```

Let's say you are in MagicalValleyController, and the MagicalValley model `has many :magical_unicorns`. The MagicalUnicorn model has an attribute called `name`. You want to return MagicalValleys that are associated with all of the MagicalUnicorns named 'Rainbow'. You could do either:

```ruby
can_filter_by_query magical_unicorn_name: ->(q, param_value) { q.joins(:magical_unicorns).where(magical_unicorns: {name: param_value}) }
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

Use `can_filter_by_query` to provide a lambda:

```ruby
can_filter_by_query a_request_param_name: ->(q, param_value) { q.joins(:some_assoc).where(some_assocs_table_name: {some_attr: param_value}) }
```

The second argument sent to the lambda is the request parameter value converted by the `convert_request_param_value_for_filtering(attr_sym, value)` method which may be customized. See elsewhere in this document for more information about the behavior of this method.

##### Customizing Request Parameter Value Conversion

Implement the `convert_request_param_value_for_filtering(attr_sym, value)` in your controller or an included module.

#### Default Filters

Specify default filters to define attributes, ARel predicates, and values to use if no filter is provided by the client with the same param name, e.g. if you have:

```ruby
  can_filter_by :attr_name_1
  can_filter_by :production_date, :creation_date, using: [:gt, :eq, :lteq]
  default_filter_by :attr_name_1, eq: 5
  default_filter_by :production_date, :creation_date, gt: 1.year.ago, lteq: 1.year.from_now
```

and both attr_name_1 and production_date are supplied by the client, then it would filter by the client's attr_name_1 and production_date and filter creation_date by both > 1 year ago and <= 1 year from now.

#### Supported Functions

##### Declaring

`supports_functions` lets you allow the functions: `distinct`, `offset`, `limit`, and `count`.

##### Distinct

In the controller:

```ruby
supports_functions :distinct
```

enables:

```
http://localhost:3000/foobars?distinct=
```

##### Count

In the controller:

```ruby
supports_functions :count
```

enables:

```
http://localhost:3000/foobars?count=
```

That will set the `@count` instance variable that you can use in your view.

##### Page Count

In the controller:

```ruby
supports_functions :page, :page_count
```

enables:

```
http://localhost:3000/foobars?page_count=
```

That will set the `@page_count` instance variable that you can use in your view.

##### Getting a Page

To access each page of results:

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

##### Offset and Limit

In the controller:

```ruby
supports_functions :offset, :limit
```

enables:

```
http://localhost:3000/foobars?offset=5
http://localhost:3000/foobars?limit=5
```

You can combine them to act like page:

```
http://localhost:3000/foobars?limit=15
http://localhost:3000/foobars?offset=15&limit=15
http://localhost:3000/foobars?offset=30&limit=15
```

#### Order

Allow request specified order:

```ruby
can_order_by :foo_date, :foo_color
```

Will let the client send the order parameter with those parameters and optional +/- prefix to designate sort direction, e.g. the following will sort by foo_date ascending then foo_color descending:

```
http://localhost:3000/foobars?order=foo_date,-foo_color
```

The `default_order_by` specifies an ordered array of hashes of attributes to sort direction or attributes that should be ascending: 

```ruby
default_order_by {:foo_date => :asc}, :foo_color, {:bar_date => :desc}
```

#### Custom Index Queries

To filter the list where the status_code attribute is 'green':

```ruby
query_for index: ->(q) { q.where(:status_code => 'green') }
```

You can also filter out items that have associations that don't have a certain attribute value (or anything else you can think up with [ARel][arel]/[ActiveRecord relations][ar]), e.g. to filter the list where the object's apples and pears associations are green:

```ruby
query_for index: ->(q) {
  q.joins(:apples, :pears)
  .where(apples: {color: 'green'})
  .where(pears: {color: 'green'})
}
```

To avoid n+1 queries, use `.includes(...)` in your query to eager load any associations that you will need in the JSON view.

#### Create Custom Actions

You are still working with regular controllers here, so add or override methods if you want more!

However `query_for` can create new action methods, e.g.:

```ruby
query_for some_action: ->(q) do
    if @current_user.admin?
      Rails.logger.debug("Notice: unfiltered results provided to admin #{@current_user.name}")
      # just make sure the relation is returned!
      q
    else
      q.where(:access => 'public')
    end        
end
```

will create an action named 'some_action'. You'll need to add views and routes, but the controller part is done.

In addition to creating the related view(s), be sure to add a route in `config/routes.rb` like:

```ruby
MyAppName::Application.routes.draw do
  resources :barfoos do
    get 'some_action', :on => :collection
  end
end
```

#### Avoid n+1 Queries

```ruby
# load all the posts and the associated category and comments for each post
including :category, :comments
```

or

```ruby
# load all of the associated posts, the associated posts’ tags and comments, and every comment’s guest association
including posts: [{comments: :guest}, :tags]
```

and action-specific:

```ruby
includes_for :create, are: [:category, :comments]
includes_for :index, :something_alias_methoded_from_index, are: [posts: [{comments: :guest}, :tags]]
```

#### Customizing Parameter Permittance

Each action except `new` defined by `RestfulJson::Controller` calls a corresponding `params_for_*` method. For `create` and `update` this calls `(model_name)_params` method expecting you to have defined that method to call `permit`, e.g.

```ruby
def foobar_params
  params.require(:foobar).permit(:name)
end
```

But, if you need action-specific permittance, just override the corresponding `params_for_*` method, e.g. if you'd like to override the params permittance for both create and update actions, you can implement the `params_for_create` and `params_for_update` methods, and you won't even need to implement a `(model_name)_params`, since those two method are what call that:

```ruby
def params_for_create
  params.require(:foobar).permit(:name, :color)
end

def params_for_update
  params.require(:foobar).permit(:color)
end
```

#### Specifying Rendering Options

If you need to change the options to use when rendering a valid response, use `valid_render_options`, e.g. if you wanted to specify the serializer option in the index render:

```ruby
valid_render_options :index, serializer: FoobarSerializer
```

Can use more than one action and more than one option.

#### Extend Your Controller with Included Concerns

The following concerns included might also be of use in your controller:

* `include ::RestfulJson::Controller::Authorizing` - on include does `before_action` to automatically call `authorize!` with the action and the controller's model class, so you can use [CanCan][cancan] or a similar authorizer.
* `include ::RestfulJson::Controller::ConvertingNullParamValuesToNil` - convert 'NULL', 'null', and 'nil' to nil when passed in as request params.
* `include ::RestfulJson::Controller::RenderingCountsAutomaticallyForNonHtml` - renders count/page count for non-html formats without a view template.
* `include ::RestfulJson::Controller::RenderingValidationErrorsAutomaticallyForNonHtml` - renders validation errors (e.g. `@my_model.errors`) for non-html formats without a view template.
* `include ::RestfulJson::Controller::UsingStandardRestRenderOptions` - use [RFC2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.2) RESTful status codes/set location for create.

#### Further Customization

Methods you can override for more control in your controller directly or in a concern/module, similar to the above:

* index
* params_for_index
* render_index(records)
* render_index_options(records)
* render_index_count(count)
* render_index_page_count(count)
* any of the above index methods for a custom action created by query_for (just replace index in the method name with your custom method name)
* show
* params_for_show
* render_show(record)
* render_show_options(record)
* edit
* params_for_edit
* render_edit(record)
* render_edit_options(record)
* create
* params_for_create
* render_create(record)
* render_create_invalid(record)
* render_create_valid(record)
* render_create_valid_options(record)
* update
* params_for_update
* render_update(record)
* render_update_invalid(record)
* render_update_valid(record)
* render_update_valid_options(record)
* destroy
* params_for_destroy
* render_destroy(record)
* render_destroy_options(record)

#### Exception Handling

Rails 4 has basic exception handling in the [public_exceptions][public_exceptions] and [show_exceptions][show_exceptions] Rack middleware.

If you want to customize Rails 4's Rack exception handling, search the web for customizing `config.exceptions_app`, although the default behavior should work for most.

You can also use `rescue_from` or `around_action` in Rails to have more control over error rendering.

### Refactoring

If you want to refactor your restful_json controllers, do it via modules/concerns, not subclassing. `include RestfulJson::Controller` defines various class attributes. These class attributes are shared by all descendants unless they are redefined. Ignoring this can lead to one controller overriding/altering the config of another.

It's helpful to have a single module you maintain that contains all of the other modules to include in your service controllers, e.g. in `config/initializers/my_service.rb`:

```ruby
module My
  module Service
    extend ::ActiveSupport::Concern
    included do
      include ::RestfulJson::Controller
      # ...
    end

    module ClassMethods
      def some_class_method
        # ...
      end
    end

    def some_instance_method
      # ...
    end
  end
end
```

And in `app/controllers/foobars_controller.rb`, you just need:

```ruby
class FoobarsController
  include My::Service

  # ...
end
```

### Release Notes

See the [changelog][changelog] for basically what happened when, and git log for everything else.

### Troubleshooting

If you get `missing FROM-clause entry for table` errors, it might mean that `including`/`includes_for` you are using are overlapping with joins that are being done in the query. This is the nasty head of AR relational includes, unfortunately.

To fix, you may decide to either: (1) change order/definition of includes in `including`/`includes_for`, (2) don't use `including`/`includes_for` for the actions it affects (may cause n+1 queries), (3) implement `apply_includes` to apply `value = value.includes(*current_action_includes)` in an appropriate order (messy), or (4) use custom query (if index/custom list action) to define joins with handcoded SQL, e.g. (thanks to Tommy):

```ruby
query_for index: ->(q) {
  # Using standard joins performs an INNER JOIN like we want, but doesn't eager load.
  # Using includes does an eager load, but does a LEFT OUTER JOIN, which isn't really what we want, but in this scenario is probably ok.
  # Using standard joins & includes results in bad SQL with table aliases.
  # So, using includes & custom joins seems like a decent solution.
  q.includes(:bartender, :waitress, :owner, :customer)
    .joins('INNER JOIN employees bartenders ON bartenders.employee_id = shifts.bartender_id')
    .joins('INNER JOIN waitresses shift_workers ON shift_workers.id = shifts.waitress_id')
    .where(bartenders: {certified: 'yes'})
    .where(shift_workers: {attitude: 'great'})
}

# set includes for all actions except index
including :owner, :customer, :bartender, :waitress

# includes specified in query_for function above
includes_for :index, are: []
```

### Contributing

Please fork, make changes in a separate branch, and do a pull request for your branch. Thanks!

### Authors

This app was written by [FineLine Prototyping, Inc.](http://www.finelineprototyping.com) by the following contributors:
* Gary Weaver (https://github.com/garysweaver)
* Tommy Odom (https://github.com/tpodom)

### License

Copyright (c) 2013 FineLine Prototyping, Inc., released under the [MIT license][lic].

[travis]: http://travis-ci.org/rubyservices/restful_json
[badgefury]: http://badge.fury.io/rb/restful_json
[employee-training-tracker]: https://github.com/FineLinePrototyping/employee-training-tracker
[built_with_angularjs]: http://builtwith.angularjs.org/
[cancan]: https://github.com/ryanb/cancan
[arel]: https://github.com/rails/arel
[ar]: http://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[public_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/public_exceptions.rb
[show_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/show_exceptions.rb
[changelog]: https://github.com/rubyservices/restful_json/blob/master/CHANGELOG.md
[lic]: http://github.com/rubyservices/restful_json/blob/master/LICENSE
