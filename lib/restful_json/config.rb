module RestfulJson
  CONTROLLER_OPTIONS = [
    :can_filter_by_default_using, 
    :debug,
    :filter_split,
    :formats,
    :number_of_records_in_a_page,
    :predicate_prefix,
    :return_resource,
    :render_enabled
  ]
  
  class << self
    CONTROLLER_OPTIONS.each{|o|attr_accessor o}
    alias_method :debug?, :debug
    def configure(&blk); class_eval(&blk); end
  end
end

RestfulJson.configure do
  self.can_filter_by_default_using = [:eq]
  self.debug = false
  self.filter_split = ','
  self.formats = :json, :html
  self.number_of_records_in_a_page = 15
  self.predicate_prefix = '!'
  self.return_resource = false
  self.render_enabled = true
end
