## restful_json 3.2.1 ##

* Important change to README that should not use acts_as_restful_json in parent/ancestor class shared by multiple controllers, because it is unsafe.
* Fixing bug in delete related to custom serializer when using AMS.
* Fixing bug in order_by.
* Working on travis-ci config and appraisals/specs for testing Rails 3.1/3.2/4.0.

## restful_json 3.2.0 ##

* Made active_model_serializers, strong_parameters, Permitters, Cancan all optional.
* Added support for strong_parameters without Permitters/Cancan, allowing *_params methods in controller.
* Fixing double rendering bug on create in 3.1.0.

## restful_json 3.1.0 ##

* Added ActiveModel Serializer custom serializer per action(s) support.
* Added JBuilder support.
* Fixing gemspec requirements to not include things it shouldn't.

## restful_json 3.0.1 ##

* Updated order_by, comments.

## restful_json 3.0.0 ##

* Controller with declaratively configured RESTful-ish JSON services, filtering, custom queries, actions, etc. using strong parameters, a.m. serializers, and Adam Hawkins (twinturbo) permitters
