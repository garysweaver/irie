module RestfulJson
  CONTROLLER_OPTIONS = [
    :can_filter_by_default_using, 
    :debug,
    :filter_split,
    :formats,
    :number_of_records_in_a_page,
    :predicate_prefix,
    :return_resource,
    :render_enabled,
    :use_permitters,
    :action_to_permitter,
    :allow_action_specific_params_methods,
    :actions_that_authorize,
    :actions_that_permit,
    :actions_supporting_params_methods,
    :avoid_respond_with,
    :return_error_data,
    :rescue_class,
    :rescue_handlers
  ]
  
  class << self
    CONTROLLER_OPTIONS.each{|o|attr_accessor o}
    alias_method :debug?, :debug
    def configure(&blk); class_eval(&blk); end
  end
end

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
  # Can use optional i18n_key for message, but will default to e.message if not found.
  # Eventually may support [DataMapper::ObjectNotFoundError], [MongoMapper::DocumentNotFound], etc.
  # If no exception_classes or exception_ancestor_classes provided, it will always match self.rescue_class.
  # Important note: if you specify classes in your configuration, do not specify as strings unless the RestfulJson railtie
  # will have a chance to convert it to constants/class objects. See railtie for more info.

  # support 404 error for ActiveRecord::RecordNotFound if using ActiveRecord
  # active_record/errors not loaded yet, so we need to try to require
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

  # add default 500 errors last
  self.rescue_handlers << {status: :internal_server_error, i18n_key: 'api.internal_server_error'.freeze}

end
