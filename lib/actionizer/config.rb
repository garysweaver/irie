module Actionizer

  CONTROLLER_OPTIONS = [
    :autoincludes,
    :available_actions,
    :available_extensions,
    :can_filter_by_default_using,
    :filter_split,
    :function_param_names,
    :id_is_primary_key_param,
    :number_of_records_in_a_page,
    :predicate_prefix
  ]

  class << self
    CONTROLLER_OPTIONS.each{|o|attr_accessor o}
    def configure(&blk); class_eval(&blk); end
  end

end

Actionizer.configure do
  
  # Default for :using in can_filter_by.
  self.can_filter_by_default_using = [:eq]
  
  # Delimiter for values in request parameter values.
  self.filter_split = ','

  # Use one or more alternate request parameter names for functions,
  # e.g. self.function_param_names = {distinct: :very_distinct, limit: [:limit, :limita]}
  self.function_param_names = {}
  
  # Delimiter for ARel predicate in the request parameter name.
  self.predicate_prefix = '.'

  # You'd set this to false if id is used for something else other than primary key.
  self.id_is_primary_key_param = true

  # Used when paging is enabled.
  self.number_of_records_in_a_page = 15

  # Actions that you can implement in the controller via include_actions,
  # e.g. include_actions :index, :show
  # Each is added as each file is required when the gem is loaded, so for a full list,
  # check ::Actionizer.available_actions in rails c.
  # You shouldn't have to worry about configuring this typically.
  self.available_actions = {}

  # Extensions to actions that you can implement in the controller via include_extensions,
  # e.g. include_extensions :count, :paging
  # Each is added as each file is required when the gem is loaded, so for a full list,
  # check ::Actionizer.available_extensions in rails c.
  # You shouldn't have to worry about configuring this typically.
  self.available_extensions = {}

  # When you include the defined action module, it includes the associated modules.
  # If value or value array contains symbol it will look up symbol in self.available_extensions in the controller
  # (which is defaulted to ::Actionizer.available_extensions).
  # If value is String will assume String is the fully-qualified module name to include, e.g. index: '::My::Module'
  # If constant, it will just include constant (module), e.g. index: ::My::Module
  self.autoincludes = {
    create: [:query_includes, :render_options],
    destroy: [:query_includes, :render_options],
    edit: [:query_includes, :render_options],
    index: [:index_query, :order, :param_filters, :query_filter, :query_includes],
    new: [],
    show: [:query_includes],
    update: [:query_includes, :render_options]
  }
end

