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
  
  # Used in param filters function.
  # Default for :using in can_filter_by.
  self.can_filter_by_default_using = [:eq]
  
  # Used in param filters function.
  # Delimiter for values in request parameter values.
  self.filter_split = ','

  # Use one or more alternate request parameter names for functions,
  # e.g. use very_distinct instead of distinct, and either limit or limita for limit
  #   self.function_param_names = {distinct: :very_distinct, limit: [:limit, :limita]}
  # Supported_functions in the controller will still expect the original name, e.g. distinct.
  self.function_param_names = {}
  
  # Used in param filters function.
  # Delimiter for ARel predicate in the request parameter name.
  self.predicate_prefix = '.'

  # Used in show, edit, update, and destroy actions.
  # In most cases the request param 'id' means primary key.
  # You'd set this to false if id is used for something else other than primary key.
  self.id_is_primary_key_param = true

  # Used in paging function.
  # Default number of records to return.
  self.number_of_records_in_a_page = 15

  # Actions you can implement in the controller, e.g. `include_actions :index, :show`
  # These are added as each file is required.
  self.available_actions = {}

  # Extensions to actions that you can implement in the controller, e.g. `include_extensions :authorizing, :count, :custom_query`
  # These are added as each is required.
  # Not recommended to include all because more may be added adding behavior you don't want,
  # but can do: include_extensions(*Actionizer.available_extensions.keys)
  self.available_extensions = {}

  # When you include the defined action module, it includes the associated modules.
  self.autoincludes = {
    create: :query_includes,
    destroy: :query_includes,
    edit: :query_includes,
    index: [:index_query, :order, :param_filters, :query_includes],
    new: :query_includes,
    show: :query_includes,
    update: :query_includes
  }
end
