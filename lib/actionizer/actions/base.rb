module Actionizer
  module Actions
    # When included, defines all Actionizer::CONTROLLER_OPTIONS as class_attributes, and
    # defines the following class_attributes if not defined with the following defaults
    # defined as singleton_methods, so that they :
    # * resource_class -> { controller_class.name.chomp('Controller').split('::').last.singularize.constantize }
    # * instance_name -> { controller_class.resource_class.name.underscore }
    # * collection_name -> { controller_class.instance_name.pluralize }
    # * instance_variable_name_sym -> { "@#{controller_class.instance_name}".to_sym }
    # * collection_variable_name_sym -> { "@#{controller_class.collection_name}".to_sym }
    # * instance_name_params_sym -> { "#{controller_class.instance_name}_params".to_sym }
    # * collection_name_params_sym -> { "#{controller_class.collection_name}_params".to_sym }
    # and then calls url_and_path_helpers.
    #
    # Also defines url and path helper methods if they don't exist, e.g. for 
    # self.collection_name="foos"/self.instance_name="foo"/FoosController, would create the following 
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
    module Base
      extend ::ActiveSupport::Concern

      included do
        # define attributes for config keys and use values from config
        Actionizer::CONTROLLER_OPTIONS.each do |key|
          class_attribute key, instance_writer: true unless respond_to?(key)
          self.send("#{key}=".to_sym, ::Actionizer.send(key)) unless self.send(key.to_sym)
        end

        include ::Actionizer::ResourceDefinition
      end

      def initialize
        logger.debug("Actionizer::Actions::Base.initialize") if Actionizer.debug?
        super
      end

      def convert_param_value(param_name, param_value)
        logger.debug("Actionizer::Actions::Base.convert_param_value(#{param_name.inspect}, #{param_value.inspect})") if Actionizer.debug?
        param_value
      end

      def aparams
        logger.debug("Actionizer::Actions::Base.aparams") if Actionizer.debug?
        method_sym = "params_for_#{params[:action]}".to_sym
        respond_to?(method_sym, true) ? (__send__(method_sym) || params) : params
      end

      def perform_render(record_or_collection, options = nil)
        logger.debug("Actionizer::Actions::Base.perform_render(#{record_or_collection.inspect}, #{options.inspect})") if Actionizer.debug?
        respond_with record_or_collection, (options || options_for_render(record_or_collection))
      end

      def options_for_render(record_or_collection)
        logger.debug("Actionizer::Actions::Base.perform_render(#{record_or_collection.inspect})") if Actionizer.debug?
        {}
      end
    end
  end
end
