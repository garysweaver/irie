class RestfulJson::BaseController < ApplicationController

  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  # note: model_class can be fully-qualified like MyModule::MySubModule::MyClass
  def restful_json_model(model_class)
    # Ensure that controller is not repurposed for different models
    return if @__restful_json_initialized
    
    #puts "Configuring #{self.name} with RESTful JSON services for #{model_class.inspect}"

    # is_a? doesn't work with classes 
    raise 'restful_json_model must be called with a model class that extends ActiveRecord::Base' unless model_class.ancestors.include?(ActiveRecord::Base)
    # this works whether or not the class is in a defined module
    unqualified_model_classname = model_class.name.split("::").last.underscore
    @__restful_json_model_singular = unqualified_model_classname
    @__restful_json_model_plural = unqualified_model_classname.pluralize
    @__restful_json_class = model_class
    instance_variable_set("@#{@__restful_json_model_plural}".to_sym, nil)
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, nil)
    puts "'#{self}' using model class: '#{@__restful_json_class}', attributes: '@#{@__restful_json_model_plural}', '@#{@__restful_json_model_singular}'"
    @__restful_json_initialized = true
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain. Modified from Tom Sheffler's example in 
  # http://www.tsheffler.com/blog/?p=428 to allow customization.
  def cors_preflight_check
    unless ENV['RESTFUL_JSON_CORS_GLOBALLY_ENABLED'] || $restful_json_cors_globally_enabled
      if request.method == :options
        headers['Access-Control-Allow-Origin'] =  '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
        headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
        headers['Access-Control-Max-Age'] = '1728000'
        # Allow one or more headers to be overriden
        headers.merge!(@__restful_json_options[:cors_preflight_headers])
        # CORS returns as text to the browser as a step before the json, so is intentionally text type and not json.
        render :text => '', :content_type => 'text/plain'
      end
    end
  end

  # For all responses in this controller, return the CORS access control headers.
  # Modified from Tom Sheffler's example in http://www.tsheffler.com/blog/?p=428
  # to allow customization.
  def cors_set_access_control_headers
    unless ENV['RESTFUL_JSON_CORS_GLOBALLY_ENABLED'] || $restful_json_cors_globally_enabled
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Max-Age'] = '1728000'
      # Allow one or more headers to be overriden
      headers.merge!(@__restful_json_options[:cors_access_control_headers])
    end
  end

  def index
    return if restful_json_controller_not_yet_configured?

    # TODO: continue to explore filtering, etc. and look into extension of this project to use Sunspot/SOLR.
    # TODO: Darrel Miller/Ted M. Young suggest reviewing these: http://stackoverflow.com/a/4028874/178651
    #       http://www.ietf.org/rfc/rfc3986.txt  http://tools.ietf.org/html/rfc6570
    # TODO: Paging. Eugen Paraschiv (a.k.a. baeldung) has a good post here, even though is in context of Spring:
    #       http://www.baeldung.com/2012/01/18/rest-pagination-in-spring/
    #       http://www.iana.org/assignments/link-relations/link-relations.
    #       More on Link header: http://blog.steveklabnik.com/posts/2011-08-07-some-people-understand-rest-and-http
    #       example of Link header:
    #       Link: </path/to/resource?other_params_go_here&page=2>; rel="next", </path/to/resource?other_params_go_here&page=9999>; rel="last"
    #       will_paginate looks like it might be a good match
    
    # Using scoped and separate wheres if params present similar to solution provided by
    # John Gibb in http://stackoverflow.com/a/5820947/178651
    value = @__restful_json_class.scoped
    allowed_activerecord_model_attribute_keys.each do |attribute_key|
      param = params[attribute_key]
      value = value.where(attribute_key => param) if param.present?
    end

    instance_variable_set("@#{@__restful_json_model_plural}".to_sym, value)
    respond_to do |format|
      format.json { render json: {@__restful_json_model_plural.to_sym => value} }
    end
  end

  def show
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.find(params[:id])
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
    respond_to do |format|
      format.json { render json: {@__restful_json_model_singular.to_sym => value} }
    end
  end

  # POST /#{model_plural}.json
  def create
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.new(params[@__restful_json_model_singular.to_sym])
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
    respond_to do |format|
      if @__restful_json_model_singular.save
        format.json { render json: {@__restful_json_model_singular.to_sym => value}, status: :created, location: value }
      else
        format.json { render json: value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /#{model_plural}/1.json
  def update
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.find(params[:id])
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
    respond_to do |format|
      if @__restful_json_model_singular.save
        format.json { render json: {@__restful_json_model_singular.to_sym => value}, status: :ok }
      else
        format.json { render json: value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /#{model_plural}/1.json
  def destroy
    return if restful_json_controller_not_yet_configured?
    @__restful_json_model_singular = @__restful_json_class.find(params[:id])
    @__restful_json_model_singular.destroy
    respond_to do |format|
      format.json { render json: nil, status: :ok }
    end
  end

private

  attr_accessor :__restful_json_class, :__restful_json_initialized, :__restful_json_model_plural, :__restful_json_model_singular, :__restful_json_options

  # Stub out actions until dynamically implemented, otherwise will get something like:
  # AbstractController::ActionNotFound (The action 'index' could not be found for SomeModelController):

  # This borrows heavily from Dan Gebhardt's example at: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
  def restful_json_controller_not_yet_configured?
    unless @__restful_json_initialized
      puts "RestfulJson controller #{self} called before setup, so returning a 503 error."
      puts "#{self}.instance_variable_names: #{self.instance_variable_names}"
      puts "#{self}.inspect: #{self.inspect}"
      respond_to do |format|
        format.json { render json: nil, status: :service_unavailable }
      end
    end
  end
  
  def restful_json_options(options)
    @__restful_json_options = options
  end

  def allowed_activerecord_model_attribute_keys
    # Solution from Jeffrey Chupp (a.k.a. 'semanticart') in http://stackoverflow.com/a/1526328/178651
    @__restful_json_class.new.attributes.keys - @__restful_json_class.protected_attributes.to_a
  end
end