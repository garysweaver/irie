module Actionizer

  CONTROLLER_OPTIONS = [
    :available_actions,
    :available_extensions,
    :available_functions,
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
  self.available_actions = {
    all: '::Actionizer::Actions::All',
    index: '::Actionizer::Actions::Index',
    show: '::Actionizer::Actions::Show',
    new: '::Actionizer::Actions::New',
    edit: '::Actionizer::Actions::Edit',
    create: '::Actionizer::Actions::Create',
    update: '::Actionizer::Actions::Update',
    destroy: '::Actionizer::Actions::Destroy'
  }

  # Extensions to actions that you can implement in the controller, e.g. `include_extensions :authorizing, :count, :custom_query`
  self.available_extensions = {
    authorizing: '::Actionizer::Extensions::Authorizing',
    converting_null_param_values_to_nil: '::Actionizer::Extensions::ConvertingNullParamValuesToNil',
    rendering_counts_automatically_for_non_html: '::Actionizer::Extensions::RenderingCountsAutomaticallyForNonHtml',
    rendering_validation_errors_automatically_for_non_html: '::Actionizer::Extensions::RenderingValidationErrorsAutomaticallyForNonHtml',
    using_standard_rest_render_options: '::Actionizer::Extensions::UsingStandardRestRenderOptions',
    count: '::Actionizer::Extensions::Count',
    custom_query: '::Actionizer::Extensions::CustomQuery',
    distinct: '::Actionizer::Extensions::Distinct',
    query_includes: '::Actionizer::Extensions::QueryIncludes',
    limit: '::Actionizer::Extensions::Limit',
    offset: '::Actionizer::Extensions::Offset',
    order: '::Actionizer::Extensions::Order',
    paging: '::Actionizer::Extensions::Paging',
    param_filters: '::Actionizer::Extensions::ParamFilters',
    query_filter: '::Actionizer::Extensions::QueryFilter'
  }
  # not recommended to include all because more may be added adding behavior you don't want,
  # but can do: include_extensions(*Actionizer.available_extensions.keys)

end
