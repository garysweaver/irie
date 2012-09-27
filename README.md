restful_json v3 for Rails 3.1+
=====

*v3.0.0 Under development!*

### v3.0.0 Changes/Current Issues

Changes:
* Config changed and almost all options gone for now to reduce complexity temporarily(?)
* restful_json may not be appropriate name. will determine later
* Using twinturbo's permitters, active_model_serializers, strong_parameters

Changes will need to make to use:
* Remove mass assignment references (no attr_accessible or attr_protected)
* No more as_json_includes or as_json_excludes
* Note that filtering and other options passed in a params not working
* Config changed

### Configuration

In your Rails 3.2.8+, < 4.0 app:

in `config/application.rb`:

    RestfulJson.debug = true

in `Gemfile`:

    gem 'active_model_serializers', '~> 0.5.2'
    gem 'strong_parameters', '~> 0.1.4'
    gem 'restful_json', '>= 3.0.0', :git => 'git://github.com/garysweaver/restful_json.git', :branch => 'integrate-twinturbo_strategy_for_param_authr'

This is *not recommended* for rails 3.2.x apps. Since using strong_parameters, we'll probably wrongly assume you are using it which may mean in `application.rb` that you might have:

    config.active_record.whitelist_attributes = false

### License

Copyright (c) 2012 Gary S. Weaver, released under the [MIT license][lic].
