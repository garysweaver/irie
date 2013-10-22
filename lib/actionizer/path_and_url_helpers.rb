module Actionizer

  # Defines url and path helper methods if they don't exist on include and
  # whenever the class is inherited.
  #
  # For self.collection_name="foos"/self.instance_name="foo"/FoosController, would create the following 
  # collection methods if they don't exist:
  # * collection_path(*args, &block)
  # * collection_url(*args, &block)
  # * foos_path(*args, &block)
  # * foos_url(*args, &block)
  # and will create the following resource methods if they don't exist:
  # * foo_path(*args, &block)
  # * foo_url(*args, &block)
  # * resource_path(*args, &block)
  # * resource_url(*args, &block)
  module PathAndUrlHelpers
    extend ::ActiveSupport::Concern

    included do
      include ::Actionizer::ResourceDefinition

      self.define_url_and_path_helpers
      class_eval "def self.inherited(subclass); subclass.define_url_and_path_helpers; super if defined?(super); end"
    end

    module ClassMethods

      def define_url_and_path_helpers
        fully_qualified_collection_url_method_pre = self.name.chomp('Controller').gsub('::','_').underscore
        fully_qualified_resource_url_method_pre = fully_qualified_collection_url_method_pre.singularize

        collection_url_method = "#{collection_name}_url".to_sym
        unless collection_name == fully_qualified_collection_url_method_pre || self.instance_methods(self).include?(collection_url_method)
          self.class_eval "def #{collection_url_method}(*args, &block) #{fully_qualified_collection_url_method_pre}_url(*args, &block);end"
        end
        if self.instance_methods(self).include?(collection_url_method) && !self.instance_methods(self).include?(:collection_url)
          self.class_eval "alias_method :collection_url, #{collection_url_method.inspect}"
        end

        collection_path_method = "#{collection_name}_path".to_sym
        unless collection_name == fully_qualified_collection_path_method_pre || self.instance_methods(self).include?(collection_path_method)
          self.class_eval "def #{collection_path_method}(*args, &block);#{fully_qualified_collection_url_method_pre}_url(*args, &block);end"
        end
        if self.instance_methods(self).include?(collection_path_method) && !self.instance_methods(self).include?(:collection_path)
          self.class_eval "alias_method :collection_path, #{collection_path_method.inspect}"
        end
        
        instance_url_method = "#{instance_name}_url".to_sym
        unless instance_name == fully_qualified_resource_url_method_pre || self.instance_methods(self).include?(instance_url_method)
          self.class_eval "def #{instance_url_method}(*args, &block);#{fully_qualified_resource_url_method_pre}_url(*args, &block);end"
        end
        if self.instance_methods(self).include?(instance_url_method) && !self.instance_methods(self).include?(:resource_url)
          self.class_eval "alias_method :resource_url, #{instance_url_method.inspect}"
        end

        instance_path_method = "#{instance_name}_path".to_sym
        unless instance_name == fully_qualified_resource_path_method_pre || self.instance_methods(self).include?(instance_path_method)
          self.class_eval "def #{instance_path_method}(*args, &block);#{fully_qualified_resource_path_method_pre}_url(*args, &block);end"
        end
        if self.instance_methods(self).include?(instance_path_method) && !self.instance_methods(self).include?(:resource_path)
          self.class_eval "alias_method :resource_path, #{instance_path_method.inspect}"
        end
      end
    
    end
  end
end
