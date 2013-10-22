module Actionizer

  CONTROLLER_OPTIONS = [
    :autoincludes,
    :available_actions,
    :available_extensions,
    :can_filter_by_default_using,
    :debug,
    :filter_split,
    :function_param_names,
    :id_is_primary_key_param,
    :number_of_records_in_a_page,
    :predicate_prefix,
    :update_should_return_entity
  ]

  class << self
    CONTROLLER_OPTIONS.each{|name|attr_accessor name; define_method("#{name}?") { !!public_send(name) } }
    def configure(&blk); class_eval(&blk); end
  end

end

Actionizer.configure do
  
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

  # When you include the defined action module, it includes the associated modules.
  # If value or value array contains symbol it will look up symbol in 
  # self.available_extensions in the controller (which is defaulted to 
  # `::Actionizer.available_extensions`). If value is String will assume String is the
  # fully-qualified module name to include, e.g. `index: '::My::Module'`, If constant,
  # it will just include constant (module), e.g. `index: ::My::Module`.
  self.autoincludes = {
    create: [:query_includes, :render_options, :resource_path_and_url],
    destroy: [:query_includes, :render_options, :resource_path_and_url],
    edit: [:query_includes, :render_options, :edit_path_and_url],
    index: [:index_query, :order, :param_filters, :query_filter, :query_includes, :collection_path_and_url],
    new: [:new_path_and_url],
    show: [:query_includes, :resource_path_and_url],
    update: [:query_includes, :render_options, :resource_path_and_url]
  }

  # By default, it sets the instance variable, but does not return entity if request
  # update, e.g. in JSON format.
  self.update_should_return_entity = false

  # Actions that you can implement in the controller via `include_actions`,
  # e.g. `include_actions :index, :show`
  # Each is added as each file is required when the gem is loaded, so for a full list,
  # check `::Actionizer.available_actions` in rails console.
  # You shouldn't have to worry about configuring this typically.
  self.available_actions = {}

  # Extensions to actions that you can implement in the controller via
  # `include_extensions`, e.g. `include_extensions :count, :paging`
  # Each is added as each file is required when the gem is loaded, so for a full list,
  # check `::Actionizer.available_extensions` in rails console.
  # You shouldn't have to worry about configuring this typically.
  self.available_extensions = {}

  # If true, will logger.debug in instance methods to help with execution tracing at
  # runtime.
  self.debug = false
end
