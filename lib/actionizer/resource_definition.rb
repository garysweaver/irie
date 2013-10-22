module Actionizer

  # Defines and sets the following and defaults values appropriately on
  # include and when inheriting class is subclassed.
  module ResourceDefinition
    extend ::ActiveSupport::Concern

    included do
      class_attribute :resource_class, instance_writer: true unless respond_to?(:resource_class, true)
      class_attribute :instance_name, instance_writer: true unless respond_to?(:instance_name, true)
      class_attribute :collection_name, instance_writer: true unless respond_to?(:collection_name, true)
      class_attribute :instance_variable_name_sym, instance_writer: true unless respond_to?(:instance_variable_name_sym, true)
      class_attribute :collection_variable_name_sym, instance_writer: true unless respond_to?(:collection_variable_name_sym, true)
      class_attribute :instance_name_params_sym, instance_writer: true unless respond_to?(:instance_name_params_sym, true)
      class_attribute :collection_name_params_sym, instance_writer: true unless respond_to?(:collection_name_params_sym, true)

      self.defaults
    end

    module ClassMethods

      def self.inherited(subclass)
        subclass.defaults
        super if defined?(super)
      end

      # Method similar to defaults method in inherited_resources that lets you set
      # :resource_class, :instance_name, :collection_name as options, e.g.
      #   defaults resource_class: Post, instance_name: 'post', collection_name: 'posts'
      # It can also be called with fewer or even no options and it will determine some
      # resource configuration information implicitly, if nil.
      def defaults(opts = {})

        if opts[:resource_class] || !self.resource_class
          self.resource_class = opts[:resource_class] || self.name.demodulize.chomp('Controller').split('::').last.singularize.constantize
        end
        
        if opts[:instance_name] || !self.instance_name
          self.instance_name = opts[:instance_name] || self.resource_class.name.underscore
          self.instance_variable_name_sym = "@#{self.instance_name}".to_sym
          self.instance_name_params_sym = "#{self.instance_name}_params".to_sym
        end

        if opts[:collection_name] || !self.collection_name
          self.collection_name = opts[:collection_name] || self.instance_name.pluralize
          self.collection_variable_name_sym = "@#{self.collection_name}".to_sym
          self.collection_name_params_sym = "#{self.collection_name}_params".to_sym
        end

        # call other handlers, like path_and_url_helpers
        resource_defined
      rescue NameError => e
        raise if opts && opts.size > 0
        # this might be normal if you intend to set configuration of the model later
        if Actionizer.debug?
          logger.debug("Actionizer::ResourceDefinition - was not able to determine model implicitly from controller name: #{self.name}. ignore this if you are setting it manually: #{e.message}\n#{e.backtrace.join(',')}")
        end
      end unless respond_to?(:defaults) # defined by inherited_resources

      def resource_defined
        # call chain of other handlers, like path_and_url_helpers, if defined
        super if defined?(super)
      end

    end
  end
end
