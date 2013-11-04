require 'inherited_resources/actions'

module InheritedResources
  # Holds all default actions for InheritedResouces.
  module Actions

    # GET /resources
    #def index(options={}, &block)
    #  object = collection
    #  logger.debug("patched index: object.to_sql before respond_with in #{__method__.to_s}: #{object.to_sql}") if Irie.debug? && object.respond_to?(:to_sql)
    #  objects = with_chain(object.to_a)
    #  logger.debug("patched index: with_chain(object).collect(&:to_sql) before respond_with in #{__method__.to_s}: #{objects.collect{|c| c.to_sql if c.respond_to?(:to_sql)}.compact.join(', ')}") if Irie.debug?
    #  logger.debug("patched index: options = #{options.inspect}")
    #  #require 'tracer'; Tracer.on do
    #  
    #  #raise "objects are #{objects.inspect}"
    #    #require 'tracer'; Tracer.on do
    #      respond_with(*objects, options, &block)
    #    #end
    #  #end
    #end
    #alias :index! :index

    # PUT /resources/1
    def update(options={}, &block)
      object = resource

      if update_resource(object, resource_params)
        options[:location] ||= smart_resource_url
      end

      respond_with_dual_blocks(object, options, &block)
    end
    alias :update! :update
  end
end

require 'inherited_resources/class_methods'

module InheritedResources
  module ClassMethods

    protected

    alias_method :orig_actions, :actions
    def actions(*actions_to_keep)
      unless actions_to_keep.empty?
        class_attribute :inherited_resources_defined_actions, instance_writer: false unless respond_to?(:inherited_resources_defined_actions)

        self.inherited_resources_defined_actions = [:index, :show, :edit, :new, :update, :create, :destroy]
        options = actions_to_keep.extract_options!
        actions_to_remove = Array(options[:except])
        actions_to_remove += ACTIONS - actions_to_keep.map { |a| a.to_sym } unless actions_to_keep.first == :all
        actions_to_remove.map! { |a| a.to_sym }.uniq!
        (instance_methods.map { |m| m.to_sym } & actions_to_remove).each do |action|
          self.inherited_resources_defined_actions -= action.to_sym
        end
      end

      orig_actions(*actions_to_keep)
    end
  end
end
