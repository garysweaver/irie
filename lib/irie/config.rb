module Irie

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
    :update_should_return_entity,
    :extension_include_order
  ]

  class << self
    CONTROLLER_OPTIONS.each{|name|attr_accessor name; define_method("#{name}?") { !!public_send(name) } }
    def configure(&blk); class_eval(&blk); end
  end

end

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

  # When you include the defined action module, it includes the associated modules.
  # If value or value array contains symbol it will look up symbol in 
  # Irie.available_extensions in the controller (which is defaulted to 
  # `::Irie.available_extensions`). If value is String will assume String is the
  # fully-qualified module name to include, e.g. `index: '::My::Module'`, If constant,
  # it will just include constant (module), e.g. `index: ::My::Module`.
  self.autoincludes = {
    create: [:query_includes],
    destroy: [:query_includes],
    edit: [:query_includes],
    index: [:index_query, :order, :param_filters, :params_to_joins, :query_filter, :query_includes],
    new: [],
    show: [:query_includes],
    update: [:query_includes]
  }

  # This ensures the correct order of includes via the extensions method. It bears no
  # relevance on whether the include is included or not. Since many includes call
  # super in their methods, the order may seem partially reversed, but this is the actual
  # include order. If extensions are not listed here, they will not be included by
  # the extensions method.
  self.extension_include_order = [
    :autorender_page_count,
    :autorender_count,
    :count,
    :paging,
    :order,
    :offset,
    :limit,
    :param_filters,
    :query_filter,
    :params_to_joins,
    :query_includes,
    :index_query,
    :nil_params
  ]

  # By default, it sets the instance variable, but does not return entity if request
  # update, e.g. in JSON format.
  self.update_should_return_entity = false

  # Extensions to actions that you can implement in the controller via
  # `include_extensions`, e.g. `include_extensions :count, :paging`
  # Each is added as each file is required when the gem is loaded, so for a full list,
  # check `::Irie.available_extensions` in rails console.
  # You shouldn't have to worry about configuring this typically.
  Irie.available_extensions = {}

  # If true, will logger.debug in instance methods to help with execution tracing at
  # runtime.
  self.debug = false
end
