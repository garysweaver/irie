[![Build Status](https://secure.travis-ci.org/rubyservices/restful_json.png?branch=master)][travis] [![Gem Version](https://badge.fury.io/rb/restful_json.png)][badgefury]

# restful_json

In Rails 4, the following implements standard Rails actions similar to a controller that makes parameter permittance, optional action authorization, and declarative query support (for use by Javascript MVC frameworks such as AngularJS and Ember) easier:

```ruby
class FoobarsController < ApplicationController
  # add standard Rails action methods
  include RestfulJson::Controller

  # standard Rails 4 respond_to: http://api.rubyonrails.org/classes/ActionController/Responder.html
  respond_to :json, :html

private
  # standard Rails 4 request params permittance: https://github.com/rails/strong_parameters
  def foobar_params
    params.require(:foobar).permit(:name)
  end
end
```

The behavior of index, other core actions, and even custom actions can be implemented and customized easily.

Typically, either the default behavior or one or two lines of filtering config is necessary for the typical JS app, but you can go nuts if you'd like. Here are some of the methods available to customize your controller:

```ruby
class FoobarsController < ApplicationController
  include RestfulJson::Controller
  respond_to :json, :html

  query_for :index, is: ->(t,q) {q.joins(:apples, :pears).where(apples: {color: 'green'}).where(pears: {color: 'green'})}
  can_filter_by :name
  can_filter_by :foo_date, :bar_date, using: [:lt, :eq, :gt], with_default: Time.now
  can_filter_by :a_request_param_name, with_query: ->(t,q,param_value) {q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value})}
  can_filter_by :and_another, through: [:some_attribute_on_this_model]
  can_filter_by :one_more, through: [:some_association, :some_attribute_on_some_association_model]
  can_filter_by :and_one_more, through: [:my_assoc, :my_assocs_assoc, :my_assocs_assocs_assoc, :an_attribute_on_my_assocs_assocs_assoc]
  supports_functions :count, :uniq, :take, :skip, :page, :page_count
  order_by {:foo_date => :asc}, :foo_color, {:bar_date => :desc}
end
```

Then, after implementing your json views, you could call these:

```
https://example.org/foobars?name=apple # gets Foo with name 'apple'
https://example.org/foobars?bar_date!gt=2012-08-08 # gets Foos with bar_date > 2012-08-08
https://example.org/foobars?bar_date!gt=2012-08-08&count= # count of Foos with bar_date > 2012-08-08
https://example.org/foobars?and_one_more=123&uniq= # distinct values of Foos where my_assoc.my_assocs_assoc.my_assocs_assocs_assoc.an_attribute_on_my_assocs_assocs_assoc is 123
https://example.org/foobars?page_count= # Foo.all.count / RestfulJson.number_of_records_in_a_page
https://example.org/foobars?page=1 # Foo.all.take(15)
https://example.org/foobars?skip=30&take=15 # Foo.all.skip(30).take(15)
```

You are declaring those methods to allow them to be called, though. The intent is for nothing to be allowed unless you define it. It's as secure as you make it.

It can also easily integrate with commonly used gems for authorization and authentication.

### Installation

In your Rails app's `Gemfile`:

```ruby
gem 'restful_json' # and use ~> and set to latest version
```

Then:

```
bundle install
```

#### Authorization

Optionally, your controller has an `authorize!(action_sym, model_class)` method like [CanCan][cancan], it will use it. If you'd like to use it, then:

```ruby
gem 'cancan' # and use ~> and set to latest compatible version
```

You can change this in the configuration or on the controller:
```ruby
self.actions_that_authorize = [:create, :update]
```

So, for example, when a create is attempted, it will first call `authorize!(:create, Foobar)`.

See the [CanCan][cancan] documentation for how to include it in your application.

### Application Configuration

The default config may be fine, but you can customize it.

Each application-level configuration option can be configured one line at a time:

```ruby
RestfulJson.number_of_records_in_a_page = 30
```

or in bulk, like:

```ruby
RestfulJson.configure do
  
  # the methods that call authorize! action_sym, @model_class, if responds to authorize!
  self.actions_that_authorize = [:create, :update]

  # default for :using in can_filter_by
  self.can_filter_by_default_using = [:eq]
  
  # delimiter for values in request parameter values
  self.filter_split = ','  
  
  # delimiter for ARel predicate in the request parameter name
  self.predicate_prefix = '.'
  
  # default number of records to return if using the page request function
  self.number_of_records_in_a_page = 15
  
end
```

You may want to put any configuration in an initializer like `config/initializers/restful_json.rb`.

### Controller Configuration

The default controller config may be fine, but you can customize it.

In the controller, you can set a variety of class attributes with `self.something = ...` in the body of your controller.

All of the app-level configuration parameters are configurable in the controller class body:

```ruby
  # the methods that call authorize! action_sym, @model_class, if responds to authorize!
  self.actions_that_authorize = [:create, :update]

  # default for :using in can_filter_by
  self.can_filter_by_default_using = [:eq]
  
  # delimiter for values in request parameter values
  self.filter_split = ','  
  
  # delimiter for ARel predicate in the request parameter name
  self.predicate_prefix = '.'
  
  # default number of records to return if using the page request function
  self.number_of_records_in_a_page = 15
```

Controller-only config options:

```ruby
self.model_class = YourModel
self.model_singular_name = 'your_model'
self.model_plural_name = 'your_models'
```

#### Default Filtering by Attribute(s)

First, declare in the controller:

```ruby
can_filter_by :foo_id # allows http://localhost:3000/foobars?foo_id=1
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
query_for :index, is: ->(t,q) {q.where(:status_code => 'green')}
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

To avoid n+1 queries, use `.includes(...)` in your query to eager load any associations that you will need in the JSON view.

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

##### Avoid n+1 Queries

```ruby
# load all the posts and the associated category and comments for each post (note: have to define .includes(...) in query_for query)
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

##### Rails 4 Default Rack Error Handling

Rails 4 has basic error handling for non-HTML formats defined in the [public_exceptions][public_exceptions] and [show_exceptions][show_exceptions] Rack middleware.

If you want to customize Rails 4's Rack exception handling, search the web for customizing `config.exceptions_app`, although the default behavior should work for most.


### Refactoring

If you want to refactor, do it via modules/concerns, not subclassing.

The reason for this is that including `RestfulJson::Controller` defines various class attributes. These class attributes are shared by all descendants unless they are redefined. Ignoring this can lead to config arrays and hashes being shared between classes, and trying to work around this is nasty. Lions and Tigers and Deep Cloning! Oh My! No, we don't do that.

### Release Notes

See the [changelog][changelog] for basically what happened when, and git log for everything else.

### Troubleshooting

If you get `missing FROM-clause entry for table` errors, it might mean that `including`/`includes_for` you are using are overlapping with joins that are being done in the query. This is the nasty head of AR relational includes, unfortunately.

To fix, you may decide to either: (1) change order/definition of includes in `including`/`includes_for`, (2) don't use `including`/`includes_for` for the actions it affects (may cause n+1 queries), (3) implement `apply_includes` to apply `value = value.includes(*current_action_includes)` in an appropriate order (messy), or (4) use custom query (if index/custom list action) to define joins with handcoded SQL, e.g. (thanks to Tommy):

```ruby
query_for :index, is: ->(t,q) {
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
