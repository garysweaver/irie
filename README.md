[![Build Status](https://secure.travis-ci.org/FineLinePrototyping/actionizer.png?branch=master)][travis] [![Gem Version](https://badge.fury.io/rb/actionizer.png)][badgefury]

# actionizer

*Looking for restful_json? Actionizer is the latest version. For the last release of restful_json, see [v4.5.1](https://github.com/FineLinePrototyping/restful_json/tree/v4.5.1).*

Implement Rails 4 controller actions easily with a clear and concise mix of declarative and imperative code, like models.

For example, to implement index, show, new, edit, create, update, and destroy methods, you can just include `Actionizer::Actions::All`:

```ruby
class PostsController < ApplicationController
  include Actionizer::Actions::All

  respond_to :json, :html

private
  
  def post_params
    params.require(:post).permit(:title, :body)
  end

end
```

or you can include the `Actionizer::Controller` module that gives you the `include_action` and `include_extensions` methods to shorten further includes, e.g. to specify request parameter-driven filtering, sorting, pagination with defaults:

```ruby
class PostsController < ApplicationController
  include Actionizer::Controller

  # These includes are just human-readable shortcuts to include modules that implement
  # the behavior. This could be refactored into one or more modules so you can include
  # common combinations.

  include_actions :index
  include_extensions :param_filters, :count, :distinct, :limit, :offset, :paging, :order

  respond_to :json, :html

  can_filter_by :author, through: [:author, :name]
  default_filter_by :author, eq: 'anonymous'
  can_filter_by :posted_on, using: [:lt, :eq, :gt]
  default_filter_by :posted_on, gt: 1.year.ago
  can_filter_by :company, through: [:author, :company, :name]
  can_order_by :posted_on, :author, :id
  default_order_by {:posted_on => :desc}, :id

end
```

Then set up your routes and views.

Now you can get posts by author:

```
https://example.org/posts?author=John
```

get posts after 2012-08-08:

```
https://example.org/posts?posted_on.gt=2012-08-08
```

count those posts:

```
https://example.org/posts?posted_on.gt=2012-08-08&count=
```

get posts by the author's company name:

```
https://example.org/posts?company=Lipton
```

find out how many pages of results there are:

```
https://example.org/posts?page_count=
```

get the first page:

```
https://example.org/posts?page=1
```

get a custom page:

```
https://example.org/posts?offset=30&limit=15
```

change the sort to ascending by author and descending by id:

```
https://example.org/posts?order=author,-id
```

define a query to allow only admins to see private posts:

```ruby
query_for index: ->(q) { @current_user.admin? ? q : q.where(:access => 'public')
end
```

change the query depending on a supplied param:

```ruby
can_filter_by_query status: ->(q, status) { status == 'all' ? q : q.where(:status => status) },
                    color: ->(q, color) { color == 'red' ? q.where("color = 'red' or color = 'ruby'") : q.where(:color => color) }
```

and more! Actionizer also provides a framework that you can use to extend controller actions with modules and share with others.

### Installation

In your Rails app's `Gemfile`:

```ruby
gem 'actionizer'
```

Then:

```
bundle install
```

### Application Configuration

Each application-level configuration option can be configured one line at a time:

```ruby
Actionizer.number_of_records_in_a_page = 30
```

or in bulk, like:

```ruby
Actionizer.configure do
  
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

  # In most cases the request param 'id' means primary key.
  # You'd set this to false if id is used for something else other than primary key.
  self.id_is_primary_key_param = true
  
end
```

You may want to put any configuration in an initializer like `config/initializers/actionizer.rb`.

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

  # In most cases the request param 'id' means primary key.
  # You'd set this to false if id is used for something else other than primary key.
  self.id_is_primary_key_param = true
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

If `Actionizer.can_filter_by_default_using = [:eq]` as it is by default, then you can now get Foobars with a foo_id of '1':

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

The second argument sent to the lambda is the request parameter value converted by the `convert_param_value(param_name, param_value)` method which may be customized. See elsewhere in this document for more information about the behavior of this method.

##### Customizing Request Parameter Value Conversion

Implement the `convert_param_value(param_name, param_value)` in your controller or an included module.

#### Default Filters

Specify default filters to define attributes, ARel predicates, and values to use if no filter is provided by the client with the same param name, e.g. if you have:

```ruby
  can_filter_by :attr_name_1
  can_filter_by :production_date, :creation_date, using: [:gt, :eq, :lteq]
  default_filter_by :attr_name_1, eq: 5
  default_filter_by :production_date, :creation_date, gt: 1.year.ago, lteq: 1.year.from_now
```

and both attr_name_1 and production_date are supplied by the client, then it would filter by the client's attr_name_1 and production_date and filter creation_date by both > 1 year ago and <= 1 year from now.

#### Extensions

##### Declaring

`supports_functions` lets you allow the functions: `distinct`, `offset`, `limit`, and `count`.

##### Distinct

In the controller:

```ruby
includes_extension :distinct
```

enables:

```
http://localhost:3000/foobars?distinct=
```

##### Count

In the controller:

```ruby
include_extension :count
```

enables:

```
http://localhost:3000/foobars?count=
```

That will set the `@count` instance variable that you can use in your view.

##### Page Count

In the controller:

```ruby
include_extensions :page, :page_count
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
Actionizer.number_of_records_in_a_page = 15
```

To set page size at controller level:

```ruby
self.number_of_records_in_a_page = 15
```

##### Offset and Limit

In the controller:

```ruby
include_extensions :offset, :limit
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

With:
```ruby
include_extension :order
```

You can allow request specified order:

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

With:
```ruby
include_extension :query_filter
```

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

##### Create Custom Actions

You are still working with regular controllers here, so you can add action methods if you want them. However, if you want another action that lists, but with a custom query, and maybe its own query includes, etc., just specify the required action name in query_for, and it will do all the `alias_method`-ing needed of `index`/`*index*` methods to `your_action`/`*your_method*` and the Actionizer implementation supports calling the method(s) appropriate for your actions. Let's say you want an action that checks `@current_user.admin?`, then:

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

will create an action named 'some_action'. You also have `render_some_action_options` and similar methods you can override to change just the behavior you want to change with things like `query_includes_for :some_action, are: [:category, :comments]` or overriding the following methods:

* some_action
* params_for_some_action
* perform_some_action(your_params)
* query_for_some_action
* some_action_filters
* after_some_action_filters
* render_some_action_options(records)
* render_some_action(records)  

In addition to creating the related view(s), be sure to add a route in `config/routes.rb` like:

```ruby
MyAppName::Application.routes.draw do
  resources :your_models do
    get 'some_action', :on => :collection
  end
end
```

Then add the views and you're done.

#### Avoid n+1 Queries

```ruby
# load all the posts and the associated category and comments for each post
query_includes :category, :comments
```

or

```ruby
# load all of the associated posts, the associated posts’ tags and comments, and every comment’s guest association
query_includes posts: [{comments: :guest}, :tags]
```

and action-specific:

```ruby
query_includes_for :create, are: [:category, :comments]
query_includes_for :index, :something_alias_methoded_from_index, are: [posts: [{comments: :guest}, :tags]]
```

#### Customizing Parameter Permittance

Each Actionizer-implemented action method except `new` calls a corresponding `params_for_*` method. For `create` and `update` this calls `(model_name)_params` method expecting you to have defined that method to call `permit`, e.g.

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

#### Other Extensions

The following concerns, which you can include via `include_extension ...` or via including the corresponding module, might also be of use in your controller:

* `:authorizing` - on include does `before_action` to automatically call `authorize!` with the action and the controller's model class, so you can use [CanCan][cancan] or a similar authorizer.
* `:converting_null_param_values_to_nil` - convert 'NULL', 'null', and 'nil' to nil when passed in as request params.
* `:rendering_counts_automatically_for_non_html` - renders count/page count for non-html formats without a view template.
* `:rendering_validation_errors_automatically_for_non_html` - renders validation errors (e.g. `@my_model.errors`) for non-html formats without a view template.
* `:using_standard_rest_render_options` - use [RFC2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.2) RESTful status codes for create and update.

#### Primary Keys

Supports composite primary keys. If `@model_class.primary_key.is_a?(Array)`, show/edit/update/destroy will use your two or more request params for the ids that make up the composite.

#### Specifying Rendering Options

If you need to change the options to use when rendering a valid response, use `valid_render_options`, e.g. if you wanted to specify the serializer option in the index render:

```ruby
valid_render_options :index, serializer: FoobarSerializer
```

Can use more than one action and more than one option.


#### Further Customization

Extensions are just modules. The only different thing is that you can `@action_result = ...; throw(:action_break)` in any method that is called by an Actionizer action and it will break the execution of the action and return `@action_result`. This allows the ease of control that you'd have typically in a single long action method, but lets you use modules to easily share action method functionality. To those unfamiliar, `throw` in Ruby is a normal flow control mechanism, unlike `raise` which is for exceptions.

Some hopefully good examples of how to extend modules are in lib/actionizer/extensions/* and the actions themselves are in lib/actionizer/actions/*. Get familiar with the code even if you don't plan on customizing, if for no other reason than to have another set of eyes on the code.

#### Exception Handling

Rails 4 has basic exception handling in the [public_exceptions][public_exceptions] and [show_exceptions][show_exceptions] Rack middleware.

If you want to customize Rails 4's Rack exception handling, search the web for customizing `config.exceptions_app`, although the default behavior should work for most.

You can also use `rescue_from` or `around_action` in Rails to have more control over error rendering.

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
query_includes :owner, :customer, :bartender, :waitress

# includes specified in query_for function above
query_includes_for :index, are: []
```

### Release Notes

See the [changelog][changelog] for basically what happened when, and git log for everything else.

### Contributing

Please fork, make changes in a separate branch, and do a pull request for your branch. Thanks!

### Authors

This app was written by [FineLine Prototyping, Inc.](http://www.finelineprototyping.com) by the following contributors:
* [Gary Weaver](https://github.com/garysweaver)
* [Tommy Odom](https://github.com/tpodom)

### License

Copyright (c) 2013 FineLine Prototyping, Inc., released under the [MIT license][lic].

[travis]: http://travis-ci.org/FineLinePrototyping/actionizer
[badgefury]: http://badge.fury.io/rb/actionizer
[employee-training-tracker]: https://github.com/FineLinePrototyping/employee-training-tracker
[built_with_angularjs]: http://builtwith.angularjs.org/
[cancan]: https://github.com/ryanb/cancan
[arel]: https://github.com/rails/arel
[ar]: http://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[public_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/public_exceptions.rb
[show_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/show_exceptions.rb
[changelog]: https://github.com/FineLinePrototyping/actionizer/blob/master/CHANGELOG.md
[lic]: http://github.com/FineLinePrototyping/actionizer/blob/master/LICENSE
