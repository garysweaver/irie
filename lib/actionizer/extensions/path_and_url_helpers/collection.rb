module Actionizer
  module Extensions
    module PathAndUrlHelpers

      # Defines collection url and path helper methods whenever update_resource_definition is called.
      #
      # For self.collection_name="foos"/self.instance_name="foo"/FoosController, would create the following 
      # methods if they don't exist:
      # * foos_path(*args, &block)
      # * foos_url(*args, &block)
      module Collection
        extend ::ActiveSupport::Concern
        ::Actionizer.available_extensions[:collection_path_and_url] = '::' + Collection.name

        included do
          include ::Actionizer::ResourceDefinition
        end

        module ClassMethods

          def resource_defined
            define_collection_url_and_path_helpers
            super if defined?(super)
          end

          def define_collection_url_and_path_helpers
            unless collection_name
              # this might be normal if you intend to set configuration of the model later
              logger.debug("Actionizer::Extensions::PathAndUrlHelpers::Collection - self.collection_name not set yet, so will expect it to be set later and define_collection_url_and_path_helpers called after that, if needed.") if Actionizer.debug?
              return
            end

            controller_namespace = self.name.deconstantize.chomp('Controller').gsub('::','_').underscore
            controller_namespace += '_' if controller_namespace.size > 0

            collection_url_method = "#{collection_name}_url".to_sym
            collection_path_method = "#{collection_name}_path".to_sym
            unless controller_namespace.size == 0
              self.class_eval "def #{collection_url_method}(*args, &block);#{controller_namespace}#{collection_url_method}(*args, &block);end"
              self.class_eval "def #{collection_path_method}(*args, &block);#{controller_namespace}#{collection_path_method}(*args, &block);end"
            end
          end
        
        end
      end
    end
  end
end
