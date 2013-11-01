[![Build Status](https://secure.travis-ci.org/FineLinePrototyping/irie.png?branch=master)][travis] [![Gem Version](https://badge.fury.io/rb/irie.png)][badgefury]

# Irie

Inherited Resources including extensions.

Extend [Inherited Resources][inherited_resources] actions with request parameter-driven filtering, sorting, pagination, and more:

```ruby
class PostsController < ApplicationController
  inherit_resources

  actions :index
  extensions :count, :distinct, :limit, :offset, :paging

  respond_to :json, :html

  can_filter_by :author, through: {author: :name}
  default_filter_by :author, eq: 'anonymous'

  can_filter_by :posted_on, using: [:lt, :eq, :gt]
  default_filter_by :posted_on, gt: 1.year.ago

  can_filter_by :company, through: {author: {company: :name}

  can_order_by :posted_on, :author, :id
  default_order_by {:posted_on => :desc}, :id

end
```

Then set up your routes and views.

Now here are some of the URLs you can hit:

```
https://example.org/posts?author=John
https://example.org/posts?posted_on.gt=2012-08-08
https://example.org/posts?posted_on.gt=2012-08-08&count=
https://example.org/posts?company=Lipton
https://example.org/posts?page_count=
https://example.org/posts?page=1
https://example.org/posts?offset=30&limit=15
https://example.org/posts?order=author,-id
```

You can also define a query to allow only admins to see private posts:

```ruby
index_query ->(q) { @current_user.admin? ? q : q.where(:access => 'public') }
```

and change the query depending on a supplied param:

```ruby
can_filter_by_query \
    status: ->(q, status) {
      status == 'all' ? q : q.where(:status => status)
    },
    color: ->(q, color) {
      if color == 'red'
        q.where("color = 'red' or color = 'ruby'")
      else
        q.where(:color => color)
      end
    }
```

Note: `extensions` also automatically includes common sets of extensions with certain actions. So, just specify `extensions` by itself can include things you can use, e.g.

```ruby
class PostsController < ApplicationController
  inherit_resources

  actions :index
  extensions
end
```

### Installation

In your Rails app's `Gemfile`:

```ruby
gem 'irie'
```

Then:


```
bundle install
```

### Application Configuration

Each application-level configuration option can be configured one line at a time:

```ruby
Irie.number_of_records_in_a_page = 30
```

or in bulk, like:

```ruby
Irie.configure do
  
  # Default for :using in can_filter_by.
  self.can_filter_by_default_using = [:eq]
  
  # Delimiter for values in request parameter values.
  self.filter_split = ','

  # Use one or more alternate request parameter names for functions, e.g.
  # `self.function_param_names = {distinct: :very_distinct, limit: [:limit, :limita]}`
  self.function_param_names = {}
  
  # Delimiter for ARel predicate in the request parameter name.
  self.predicate_prefix = '.'

  # You'd set this to false if id is used for something else other than primary key.
  self.id_is_primary_key_param = true

  # Used when paging is enabled.
  self.number_of_records_in_a_page = 15

  # Included if the action method exists when `extensions` is called.
  self.autoincludes = {
    create: [:query_includes],
    destroy: [:query_includes],
    edit: [:query_includes],
    index: [:index_query, :order, :param_filters, :query_filter, :query_includes],
    new: [],
    show: [:query_includes],
    update: [:query_includes]
  }

end
```

You may want to put your configuration in an initializer like `config/initializers/irie.rb`.

### Controller Configuration

The default controller config may be fine, but you can customize it.

In the controller, you can set a variety of class attributes with `self.something = ...` in the body of your controller.

All of the app-level configuration parameters are configurable in the controller class body, e.g.:

```ruby
  self.can_filter_by_default_using = [:eq]
  self.filter_split = ','
  self.function_param_names = {}
  self.predicate_prefix = '.'
  self.number_of_records_in_a_page = 15
  self.id_is_primary_key_param = true
  self.update_should_return_entity = false
```

#### About Extensions

As you may have noticed in `autoincludes`, some concerns are included as a package along with the action include.

The following assumes that you are using the default autoincludes and included the relevant action.

#### Filtering by Attribute(s)

`can_filter_by` filters the index action the request parameter name as a symbol will filter the results by the value of that request parameter, e.g.:

```ruby
can_filter_by :title
```

allows you to filter by title:

```
http://localhost:3000/posts?title=Awesome
```

If you do `Arel::Predications.public_instance_methods.sort` in Rails console, you can see a list of the available predicates:

```ruby
:does_not_match, :does_not_match_all, :does_not_match_any, :eq, :eq_all, :eq_any, :gt,
:gt_all, :gt_any, :gteq, :gteq_all, :gteq_any, :in, :in_all, :in_any, :lt, :lt_all,
:lt_any, :lteq, :lteq_all, :lteq_any, :matches, :matches_all, :matches_any, :not_eq,
:not_eq_all, :not_eq_any, :not_in, :not_in_all, :not_in_any
```

`:using` means you can use those [ARel][arel] predicates for filtering:

```ruby
can_filter_by :seen_on, using: [:gteq, :eq_any]
```

By appending the predicate prefix (`.` by default) to the request parameter name, you can use any [ARel][arel] predicate you allowed, e.g.:

```
http://localhost:3000/posts?seen_on.gteq=2012-08-08
```

And `can_filter_by` can specify a `:through` which (inner) joins and sets the deepest symbol in the hash as the key for the parameter value, then does a where, e.g.:

```ruby
can_filter_by :name, through: {company: {employee: :full_name}}
```

If a MagicalUnicorn `has_many :friends` and a MagicalUnicorn's friend has a name attribute:

```ruby
can_filter_by :magical_unicorn_friend_name,
              through: {magical_unicorns:{friends: :name}}
```

and use this to get valleys associated with unicorns who in turn have a friend named Oscar:

```
http://localhost:3000/magical_valleys?magical_unicorn_friend_name=Oscar
```

Use `can_filter_by_query` to provide a lambda:

```ruby
can_filter_by_query a_request_param_name: ->(q, param_value) {
  q.joins(:some_assoc).where(some_assocs_table_name: {some_attr: param_value})
}
```

The second argument sent to the lambda is the request parameter value converted by the `convert_param_value(param_name, param_value)` method which may be customized. See elsewhere in this document for more information about the behavior of this method.

The return value of the lambda becomes the new query, so you could really change the behavior of the query depending on the request parameter provided.

##### Customizing Request Parameter Value Conversion

Implement the `convert_param_value(param_name, param_value)` in your controller or an included module.

#### Default Filters

Specify default filters to define attributes, ARel predicates, and values to use if no filter is provided by the client with the same param name, e.g. if you have:

```ruby
  can_filter_by :attr_name_1
  can_filter_by :production_date, :creation_date, using: [:gt, :eq, :lteq]
  default_filter_by :attr_name_1, eq: 5
  default_filter_by :production_date, :creation_date, gt: 1.year.ago,
                    lteq: 1.year.from_now
```

and both attr_name_1 and production_date are supplied by the client, then it would filter by the client's attr_name_1 and production_date and filter creation_date by both > 1 year ago and <= 1 year from now.

#### Extensions

##### Distinct

In the controller:

```ruby
extensions :distinct
```

enables:

```
http://localhost:3000/posts?distinct=
```

##### Count

In the controller:

```ruby
extensions :count
```

enables:

```
http://localhost:3000/posts?count=
```

That will set the `@count` instance variable that you can use in your view.

Use `extensions :autorender_count` to render count automatically for non-HTML (JSON, etc.) views.

##### Page Count

In the controller:

```ruby
extensions :paging
```

enables:

```
http://localhost:3000/posts?page_count=
```

That will set the `@page_count` instance variable that you can use in your view.

Use `extensions :autorender_page_count` to render count automatically for non-HTML (JSON, etc.) views.

##### Getting a Page

In the controller:

```ruby
extensions :paging
```

To access each page of results:

```
http://localhost:3000/posts?page=1
http://localhost:3000/posts?page=2
```

To set page size at application level:

```ruby
Irie.number_of_records_in_a_page = 15
```

To set page size at controller level:

```ruby
self.number_of_records_in_a_page = 15
```

##### Offset and Limit

In the controller:

```ruby
extensionss :offset, :limit
```

enables:

```
http://localhost:3000/posts?offset=5
http://localhost:3000/posts?limit=5
```

You can combine them to act like page:

```
http://localhost:3000/posts?limit=15
http://localhost:3000/posts?offset=15&limit=15
http://localhost:3000/posts?offset=30&limit=15
```

#### Order

You can allow request specified order:

```ruby
can_order_by :foo_date, :foo_color
```

Will let the client send the order parameter with those parameters and optional +/- prefix to designate sort direction, e.g. the following will sort by foo_date ascending then foo_color descending:

```
http://localhost:3000/posts?order=foo_date,-foo_color
```

The `default_order_by` specifies an ordered array of ascending attributes and/or hashes of attributes to sort direction: 

```ruby
default_order_by :posted_at => :desc, :id => :desc
```

or:

```ruby
default_order_by {:this_is_desc => :desc}, :this_is_asc,
                 {:no_different_than_a_symbol => :asc},
                 :this_is_asc_also, :id => :desc
```

#### Custom Index Queries

To filter the list where the status_code attribute is 'green':

```ruby
index_query ->(q) { q.where(:status_code => 'green') }
```

You can also filter out items that have associations that don't have a certain attribute value (or anything else you can think up with [ARel][arel]/[ActiveRecord relations][ar]), e.g. to filter the list where the object's apples and pears associations are green:

```ruby
index_query ->(q) {
  q.joins(:apples, :pears)
  .where(apples: {color: 'green'})
  .where(pears: {color: 'green'})
}
```

To avoid n+1 queries, use `.includes(...)` in your query to eager load any associations that you will need in the JSON view.

#### Specifying Rendering Options

If you wanted to specify the serializer option in the index:

```ruby
render_options :index, serializer: PostSerializer
```

(You can use more than one action and more than one option.)

Also available are `render_valid_options` and `render_invalid_options` (when record/collection respond to `.errors` and has more than one error) that are merged into any `render_options` you provide. (Please see the Exception Handling section for information about handling exceptions.)

For more control, you can either implement `options_for_render(record_or_collection)`, or both `options_for_collection_render(records)` for index, and `options_for_render(record)` for other actions. Or, implement any action's `render_*(...)` method (where * is the action name).

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
query_includes_for :index, :show, are: [posts: [{comments: :guest}, :tags]]
```

#### Customizing Parameter Permittance

Each Irie-implemented action method except `new` calls a corresponding `params_for_*` method. For `create` and `update` this calls `(model_name)_params` method expecting you to have defined that method to call `permit`, e.g.

```ruby
def post_params
  params.require(:post).permit(:name)
end
```

But, if you need action-specific permittance, just override the corresponding `params_for_*` method, e.g. if you'd like to override the params permittance for both create and update actions, you can implement the `params_for_create` and `params_for_update` methods, and you won't even need to implement a `(model_name)_params`, since those two method are what call that:

```ruby
def params_for_create
  params.require(:post).permit(:name, :color)
end

def params_for_update
  params.require(:post).permit(:color)
end
```

#### Using define_params vs :through option

The `:through` option in `can_filter_by` and `can_order_by` just uses `define_params` to set the attribute name alias and options (which is parsed into a joins hash and attribute name internally). So, if you don't mind a little more typing, it might make the intent clearer, e.g.

```ruby
define_params name: {company: {employee: :full_name}},
              color: :external_color
can_filter_by :name
default_filter_by :name, eq: 'Guest'
can_order_by :color
default_filter_by :color, eq: 'blue'
```

#### Other Extensions

The following concerns, which you can include via `extensions ...` or via including the corresponding module, might also be of use in your controller:

* `:nil_params` - convert 'NULL', 'null', and 'nil' to nil when passed in as request params.
* `:autorender_errors` - renders validation errors (e.g. `@my_model.errors`) for non-HTML (JSON, etc.) formats without a view template.

#### Writing Your Own Extensions

Extensions are just modules. There is no magic.

The somewhat special thing about Irie extensions if that you can `@action_result = ...; throw(:action_break)` in any method that is called by an Irie action and it will break the execution of the action and return `@action_result`. This allows the ease of control that you'd have typically in a single long action method, but lets you use modules to easily share action method functionality. To those unfamiliar, `throw` in Ruby is a normal flow control mechanism, unlike `raise` which is for exceptions.

Some hopefully good examples of how to extend modules are in lib/irie/extensions/* and the actions themselves are in lib/irie/actions/*. Get familiar with the code even if you don't plan on customizing, if for no other reason than to have another set of eyes on the code.

Here's another example:

```ruby
# Converts all 'true' and 'false' param values to true and false
module BooleanParams
  extend ::ActiveSupport::Concern

  def convert_param_value(param_name, param_value)
    case param_value
    when 'true'
      true
    when 'false'
      false
    else
      super if defined?(super)
    end
  end

end
```

If you are just doing regular `include`'s in your controllers, that's all you need. If you'd like to use `extensions`, you get autoincludes and can use symbols, e.g. in `app/controllers/concerns/service_controller.rb`:

```ruby
module ServiceController
  extend ::ActiveSupport::Concern

  included do
    inherit_resources
    respond_to :json

    # reference as string so we don't load the concern before it is used.
    
    ::Irie.available_extensions[:boolean_params] = '::BooleanParams'

    # this is order of inclusion but often the order is not the same as its
    # effective execution, e.g. often super is called at the beginning of a
    # composed collection method to work with I.R.'s collection, but that in
    # turn calls the next include up the chain, effectively somewhat 
    # reversing the execution order of the extensions.
    #
    # so, for anything that wants to be at the beginning of a filter chain,
    # like param value conversion, it may be ok to use +=, e.g.
    #   ::Irie.extension_include_order += :an_ext
    # to include before :count (for example), use:
    #   ::Irie.extension_include_order.insert
    #     ::Irie.extension_include_order.index(:count)), :ext_a, :ext_b
    # to include at the end, use unshift, e.g.:
    #   ::Irie.extension_include_order.unshift :an_ext
    # so in this case, we just append since we want it included last.
    # The more explicit way to do it is to redefine the entire order list
    # here or in the initializer for Irie configuration.

    ::Irie.extension_include_order += :boolean_params
  end

end
```

Now you could use this in your controller:

```ruby
include ServiceController

actions :index
extensions :boolean_params
```

Doing that doesn't make as much sense when you just have modules in the root namespace, but it might if you have longer namespaces for organization and to avoid class/module name conflicts.

#### Primary Keys

Supports composite primary keys. If `resource_class.primary_key.is_a?(Array)`, show/edit/update/destroy will use your two or more request params for the ids that make up the composite.

#### Exception Handling

Rails 4 has basic exception handling in the [public_exceptions][public_exceptions] and [show_exceptions][show_exceptions] Rack middleware.

If you want to customize Rails 4's Rack exception handling, search the web for customizing `config.exceptions_app`, although the default behavior should work for most.

You can also use `rescue_from` or `around_action` in Rails to have more control over error rendering.

### Troubleshooting

#### Irie::Extensions::QueryIncludes

If you get `missing FROM-clause entry for table` errors, it might mean that `query_includes`/`query_includes_for` you are using are overlapping with joins that are being done in the query. This is the nasty head of AR relational includes, unfortunately.

To fix, you may decide to either: (1) change order/definition of includes in `query_includes`/`query_includes_for`, (2) don't use `query_includes`/`query_includes_for` for the actions it affects (may cause n+1 queries), (3) implement `apply_includes` to do includes in an appropriate order (messy), or (4) use custom query (if index/custom list action) to define joins with handcoded SQL, e.g. (thanks to Tommy):

```ruby
index_query ->(q) {
  # Using standard joins performs an INNER JOIN like we want, but doesn't
  # eager load.
  # Using includes does an eager load, but does a LEFT OUTER JOIN, which
  # isn't really what we want, but in this scenario is probably ok.
  # Using standard joins & includes results in bad SQL with table aliases.
  # So, using includes & custom joins seems like a decent solution.
  q.includes(:bartender, :waitress, :owner, :customer)
    .joins('INNER JOIN employees bartenders ON bartenders.employee_id = ' +
    'shifts.bartender_id')
    .joins('INNER JOIN waitresses shift_workers ON shift_workers.id = ' +
    'shifts.waitress_id')
    .where(bartenders: {certified: 'yes'})
    .where(shift_workers: {attitude: 'great'})
}

# set includes for all actions except index
query_includes :owner, :customer, :bartender, :waitress

# includes specified in index query
query_includes_for :index, are: []
```

#### Debugging Includes

##### Logging

If you enabled Irie's debug option via:

```ruby
Irie.debug = true
```

Then all the included modules (actions, extensions) will use `logger.debug ...` to log some information about what is executed.

To log debug to console only in your tests, you could put this in your test helper:

```ruby
::Irie.debug = true
ActionController::Base.logger = Logger.new(STDOUT)
ActionController::Base.logger.level = Logger::DEBUG
```

However, that might not catch all the initialization debug logging that could occur. Instead, you might put the following into the block in `config/environments/test.rb`:

```ruby
::Irie.debug = true
config.log_level = :debug
```

### restful_json

The project was originally named [restful_json][restful_json]. Old commit tags corresponding to restful_json versions may be found in [legacy][legacy].

### Release Notes

See [changelog][changelog] and git log.

### Contributing

Please fork, make changes in a separate branch, and do a pull request. Thanks!

### Authors

This was written by [FineLine Prototyping, Inc.](http://www.finelineprototyping.com) by the following contributors:
* [Gary Weaver](https://github.com/garysweaver)
* [Tommy Odom](https://github.com/tpodom)

### License

Copyright (c) 2013 FineLine Prototyping, Inc., released under the [MIT license][lic].

[travis]: http://travis-ci.org/FineLinePrototyping/irie
[badgefury]: http://badge.fury.io/rb/irie
[arel]: https://github.com/rails/arel
[ar]: http://api.rubyonrails.org/classes/ActiveRecord/Relation.html
[public_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/public_exceptions.rb
[show_exceptions]: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/show_exceptions.rb
[changelog]: https://github.com/FineLinePrototyping/irie/blob/master/CHANGELOG.md
[inherited_resources]: https://github.com/josevalim/inherited_resources
[restful_json]: http://rubygems.org/gems/restful_json
[legacy]: http://github.com/FineLinePrototyping/irie/blob/master/LEGACY.md
[lic]: http://github.com/FineLinePrototyping/irie/blob/master/LICENSE
