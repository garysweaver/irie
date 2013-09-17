module Actionize

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

Actionize.configure do
  
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
    all: '::Actionize::Actions::All',
    index: '::Actionize::Actions::Index',
    show: '::Actionize::Actions::Show',
    new: '::Actionize::Actions::New',
    edit: '::Actionize::Actions::Edit',
    create: '::Actionize::Actions::Create',
    update: '::Actionize::Actions::Update',
    destroy: '::Actionize::Actions::Destroy'
  }

  # Extensions you can implement in the controller, e.g. `include_extensions :count, :custom_query`
  self.available_extensions = {
    all: '::Actionize::Extensions::All',
    authorizing: '::Actionize::Extensions::Authorizing',
    converting_null_param_values_to_nil: '::Actionize::Extensions::ConvertingNullParamValuesToNil',
    rendering_counts_automatically_for_non_html: '::Actionize::Extensions::RenderingCountsAutomaticallyForNonHtml',
    rendering_validation_errors_automatically_for_non_html: '::Actionize::Extensions::RenderingValidationErrorsAutomaticallyForNonHtml',
    using_standard_rest_render_options: '::Actionize::Extensions::UsingStandardRestRenderOptions'
  }

  # Functions you can implement in the controller, e.g. `include_functions :count, :custom_query`
  self.available_functions = {
    all: '::Actionize::Functions::All',
    count: '::Actionize::Functions::Count',
    custom_query: '::Actionize::Functions::CustomQuery',
    distinct: '::Actionize::Functions::Distinct',
    query_includes: '::Actionize::Functions::QueryIncludes',
    limit: '::Actionize::Functions::limit',
    offset: '::Actionize::Functions::Offset',
    order: '::Actionize::Functions::Order',
    paging: '::Actionize::Functions::Paging',
    param_filters: '::Actionize::Functions::ParamFilters',
    query_filters: '::Actionize::Functions::QueryFilters'
  }

end
