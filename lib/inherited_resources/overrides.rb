module InheritedResources
  # Holds all default actions for InheritedResouces.
  module Actions

    # GET /resources
    def index(options={}, &block)
      object = collection
      logger.debug("patched index: object.to_sql before respond_with in #{__method__.to_s}: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)
      objects = with_chain(object.to_a)
      logger.debug("patched index: with_chain(object).collect(&:to_sql) before respond_with in #{__method__.to_s}: #{objects.collect{|c| c.to_sql if c.respond_to?(:to_sql)}.compact.join(', ')}") if Irie.debug?
      logger.debug("patched index: options = #{options.inspect}")
      #require 'tracer'; Tracer.on do
        respond_with(*objects, options, &block)
      #end
    end
    alias :index! :index
  end
end
