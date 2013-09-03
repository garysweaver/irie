module RestfulJson

  CONTROLLER_OPTIONS = [
    :can_filter_by_default_using, 
    :filter_split,
    :number_of_records_in_a_page,
    :predicate_prefix
  ]

  class << self
    CONTROLLER_OPTIONS.each{|o|attr_accessor o}
    def configure(&blk); class_eval(&blk); end
  end

end

RestfulJson.configure do
  
  # default for :using in can_filter_by
  self.can_filter_by_default_using = [:eq]
  
  # delimiter for values in request parameter values
  self.filter_split = ','  
  
  # delimiter for ARel predicate in the request parameter name
  self.predicate_prefix = '.'
  
  # default number of records to return if using the page request function
  self.number_of_records_in_a_page = 15

end
