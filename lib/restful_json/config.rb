module RestfulJson
  CONTROLLER_OPTIONS = [:debug]
  class << self
    attr_accessor :debug
    alias_method :debug?, :debug
    def configure(&blk); class_eval(&blk); end
  end
end