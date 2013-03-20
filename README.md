restful_json
=====

Develop declarative, featureful JSON RESTful-ish service controllers to use with modern Javascript MVC frameworks like AngularJS, Ember, etc. with much less code.

Should work with Rails 3.1+ and Rails 4. Feel free to submit issues and/or do a pull requests if you run into anything.

Uses Adam Hawkin's [permitter][permitter] code which uses [strong_parameters][strong_parameters] and encourages use of [active_model_serializers][active_model_serializers].

An example app using restful_json with AngularJS is [employee-training-tracker][employee-training-tracker], as featured in [Built with AngularJS][built_with_angularjs].

### Installation

In your Rails app's `Gemfile`, add:

    gem 'restful_json'

and:

    bundle install

### Setup

#### Cancan

You need to setup [cancan][cancan]. Here are the basics:

In your `app/controllers/application_controller.rb` or in your service controllers, make sure `current_user` is set:

    class ApplicationController < ActionController::Base
      protect_from_forgery

      def current_user
        User.new
      end
    end

You could do that better by setting up some real authentication with [Authlogic][authlogic], [Devise][devise], or whatever cancan will support.

In `app/models/ability.rb`, setup a basic cancan ability. Just for testing we'll allow everything:

    class Ability
      include CanCan::Ability

      def initialize(user)
        can :manage, :all
      end
    end

#### Strong Parameters

If you're using Rails 3.1.x/3.2.x and you want to disable the default whitelisting that occurs in later versions of Rails because you are going to use Strong Parameters, change the config.active_record.whitelist_attributes property in your `config/application.rb`:

    config.active_record.whitelist_attributes = false

This will allow you to remove / not have to use attr_accessible and do mass assignment inside your code and tests. Instead you will put this information into your permitters.

Note that restful_json automatically includes `ActiveModel::ForbiddenAttributesProtection` on all models, as is done in Rails 4.

### Configuration

At the bottom of `config/environment.rb`, you can set config items one at a time like:

    RestfulJson.debug = true

or in bulk like:

    RestfulJson.configure do
      self.can_filter_by_default_using = [:eq] # default for :using in can_filter_by
      self.debug = false # to output debugging info during request handling
      self.filter_split = ',' # delimiter for values in request parameter values
      self.formats = :json, :html # equivalent to specifying respond_to :json, :html in the controller, and can be overriden in the controller. Note that by default responders gem sets respond_to :html in application_controller.rb.
      self.number_of_records_in_a_page = 15 # default number of records to return if using the page request function
      self.predicate_prefix = '!' # delimiter for ARel predicate in the request parameter name
      self.return_resource = false # if true, will render resource and HTTP 201 for post/create or resource and HTTP 200 for put/update
    end

#### Advanced Configuration

In the controller, you can set a variety of class attributes with `self.something = ...` in the body of your controller.

If you don't use the standard controller naming convention, you can define this in the controller:

        self.model_class = YourModel

If it doesn't handle the other forms well, you can explicitly define the singular/plural names:

        self.model_singular_name = 'your_model'
        self.model_plural_name = 'your_models'

Those are used for *_url method definitions, to set instance variables like `@foobar` and `@foobars` dynamically, etc.

Other class attributes available for setting/overriding, but they are all set by the other class methods.

### Usage

By using `acts_as_restful_json`, you have a configurable generic Rails 3.1+/4+ controller that does the index, show, create, and update and other custom actions easily for you.

Everything is well-declared and fairly concise.

You can have something as simple as:

    class FoobarsController < ApplicationController
      
      acts_as_restful_json

    end

which would use the restful_json configuration and the controller's classname for the service definition, or something a lot more complex like:

    class FoobarsController < ApplicationController
      
      acts_as_restful_json
      
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
      
      # comma-delimited if you want more than :json, e.g. :json, :html
      respond_to :json, :html
      
    end

#### Default Filter by Attribute(s)

First, declare in the controller:

    can_filter_by :foo_id

If `RestfulJson.can_filter_by_default_using = [:eq]` as it is by default, then you can now get Foobars with a foo_id of '1':

    http://localhost:3000/foobars?foo_id=1

`can_filter_by` without an option means you can send in that request param (via routing or directly, just like normal in Rails) and it will use that in the ARel query (safe from SQL injection and only letting you do what you tell it). `:using` means you can use those [ARel][arel] predicates for filtering. For a full list of available ones do:

    rails c
    Arel::Predications.public_instance_methods.sort

at time of writing these were:

    [:does_not_match, :does_not_match_all, :does_not_match_any, :eq, :eq_all, :eq_any, :gt, :gt_all, :gt_any, :gteq, :gteq_all, :gteq_any, :in, :in_all, :in_any, :lt, :lt_all, :lt_any, :lteq, :lteq_all, :lteq_any, :matches, :matches_all, :matches_any, :not_eq, :not_eq_all, :not_eq_any, :not_in, :not_in_all, :not_in_any]

`can_filter_by` can also specify a `:with_query` to provide a lambda that takes the request parameter in when it is provided by the request.

And `can_filter_by` can also specify a `:through` to provide an easy way to inner join through a bunch models (using ActiveRecord relations) by specifying 0-to-many association names to go "through" to the final argument which is the attribute name on the last model, e.g. the two following are equivalent:

    can_filter_by :a_request_param_name, with_query: ->(t,q,param_value) {q.joins(:some_assoc).where(:some_assocs_table_name=>{some_attr: param_value})}
    can_filter_by :a_request_param_name, through: [:some_assoc, :some_attr] # much easier, but not as flexible as a lambda

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

To return a simple unique view of a model, combine use of an active_model_serializer that returns just the attribute you want along with the uniq param, e.g. to return unique/distinct colors of foobars you'd have a serializer to just return the color and then use:

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

The goal of restful_json is to reduce service controller code in an intuitive way, not to be a be-all DSL, so there is no "restful_json way".

### Routing

Respects regular and nested Rails resourceful routing and controller namespacing, e.g. in `config/routes.rb`:

    MyAwesomeApp::Application.routes.draw do
      namespace :my_service_controller_module do
        resources :foobars
        # why use nested if you only want to provide ways of querying via path
        match 'bars/:bar_id/foobars(.:format)' => 'foobars#index'
      end
    end

### Thanks!

Without our users, where would we be? Feedback, bug reports, and code/documentation contributions are always welcome!

### Contributors

* Gary Weaver (https://github.com/garysweaver)
* Tommy Odom (https://github.com/tpodom)

### License

Copyright (c) 2012 Gary S. Weaver, released under the [MIT license][lic].

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
[lic]: http://github.com/rubyservices/restful_json/blob/master/LICENSE
