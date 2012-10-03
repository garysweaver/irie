module RestfulJson
  CONTROLLER_OPTIONS = [
    :can_filter_by_default_using, 
    :debug, 
    :filter_split,
    :predicate_prefix
  ]
  
  class << self
    attr_accessor CONTROLLER_OPTIONS
    alias_method :debug?, :debug
    def configure(&blk); class_eval(&blk); end
  end
end

RestfulJson.configure do
  self.can_filter_by_default_using = [:eq]
  self.predicate_prefix = '!'
  self.filter_split = ','
end
