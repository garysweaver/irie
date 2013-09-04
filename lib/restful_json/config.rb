module RestfulJson

  CONTROLLER_OPTIONS = [
    :can_filter_by_default_using,
    :filter_split,
    :function_param_names,
    :number_of_records_in_a_page,
    :predicate_prefix
  ]

  class << self
    CONTROLLER_OPTIONS.each{|o|attr_accessor o}
    def configure(&blk); class_eval(&blk); end
  end

end

RestfulJson.configure do
  
  # Default for :using in can_filter_by.
  self.can_filter_by_default_using = [:eq]
  
  # Delimiter for values in request parameter values.
  self.filter_split = ','

  # Use one or more alternate request parameter names for functions,
  # e.g. use z_uniq instead of uniq, and allow translations of take:
  #   self.function_param_names = {uniq: :z_uniq, take: [:take, :nehmen, :prendre]}
  # Supported_functions in the controller will still expect the original name, e.g. uniq.
  self.function_param_names = {}
  
  # Delimiter for ARel predicate in the request parameter name.
  self.predicate_prefix = '.'
  
  # Default number of records to return if using the page request function.
  self.number_of_records_in_a_page = 15

end
