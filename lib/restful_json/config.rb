module RestfulJson
  class << self
    CONTROLLER_OPTIONS = [:debug]
    attr_accessor :debug
    alias_method :debug?, :debug
    def configure(&blk); class_eval(&blk); end
  end
end