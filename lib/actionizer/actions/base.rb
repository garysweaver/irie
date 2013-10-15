module Actionizer
  module Actions
    module Base
      extend ::ActiveSupport::Concern

      included do
        # define attributes for config keys and use values from config
        Actionizer::CONTROLLER_OPTIONS.each do |key|
          class_attribute key, instance_writer: true unless respond_to?(key)
          self.send("#{key}=".to_sym, ::Actionizer.send(key)) unless self.send(key.to_sym)
        end

        controller_class = self.to_s.start_with?('#<') ? self.class : self

        class_attribute :resource_class, instance_writer: true unless respond_to?(:resource_class, true)
        define_singleton_method :resource_class, -> { controller_class.name.chomp('Controller').split('::').last.singularize.constantize }
        class_attribute :instance_name, instance_writer: true unless respond_to?(:instance_name, true)
        define_singleton_method :instance_name, -> { controller_class.resource_class.name.underscore }
        class_attribute :collection_name, instance_writer: true unless respond_to?(:collection_name, true)
        define_singleton_method :collection_name, -> { controller_class.instance_name.pluralize }
        class_attribute :instance_variable_name_sym, instance_writer: true unless respond_to?(:instance_variable_name_sym, true)
        define_singleton_method :instance_variable_name_sym, -> { "@#{controller_class.instance_name}".to_sym }
        class_attribute :collection_variable_name_sym, instance_writer: true unless respond_to?(:collection_variable_name_sym, true)
        define_singleton_method :collection_variable_name_sym, -> { "@#{controller_class.collection_name}".to_sym }
        class_attribute :instance_name_params_sym, instance_writer: true unless respond_to?(:instance_name_params_sym, true)
        define_singleton_method :instance_name_params_sym, -> { "#{controller_class.instance_name}_params".to_sym }
        class_attribute :collection_name_params_sym, instance_writer: true unless respond_to?(:collection_name_params_sym, true)
        define_singleton_method :collection_name_params_sym, -> { "#{controller_class.collection_name}_params".to_sym }
      end

      def initialize
        logger.debug("Actionizer::Actions::Base.initialize") if Actionizer.debug?
        super

        raise "#{self.class.name} failed to initialize. self.resource_class cannot be nil in #{self}" if resource_class.nil?

        # This is a workaround for controllers that are in a different module than the model only works if the controller's base part of the unqualified name in the plural model name.
        # If the model name is different than the controller name, you will need to define methods to return the right urls.
        plural_url_method = "#{collection_name}_url".to_sym
        singular_url_method = "#{instance_name}_url".to_sym
        underscored_modules_and_underscored_plural_model_name = self.class.name.chomp('Controller').gsub('::','_').underscore
        singularized_underscored_modules_and_underscored_plural_model_name = underscored_modules_and_underscored_plural_model_name
        class_eval "def #{plural_url_method};#{underscored_modules_and_underscored_plural_model_name}_url;end" unless collection_name == underscored_modules_and_underscored_plural_model_name || self.class.instance_methods(false).include?(plural_url_method)
        class_eval "def #{singular_url_method}(record);#{singularized_underscored_modules_and_underscored_plural_model_name}_url(record);end" unless instance_name == singularized_underscored_modules_and_underscored_plural_model_name || self.class.instance_methods(false).include?(singular_url_method)
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
