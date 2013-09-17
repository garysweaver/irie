module Actionize
  module Actions
    module Base
      extend ::ActiveSupport::Concern

      included do
        # define attributes for config keys and use values from config
        Actionize::CONTROLLER_OPTIONS.each do |key|
          class_attribute key, instance_writer: true
          self.send("#{key}=".to_sym, 
            Actionize.send(key))
        end

        # create class attributes for each controller option
        class_attribute :action_to_query, instance_writer: true
        class_attribute :action_to_query_includes, instance_writer: true
        class_attribute :action_to_valid_render_options, instance_writer: true
        class_attribute :model_class, instance_writer: true
        class_attribute :model_singular_name, instance_writer: true
        class_attribute :model_plural_name, instance_writer: true
        
        self.action_to_query ||= {}
        self.action_to_query_includes ||= {}
        self.action_to_valid_render_options ||= {}
      end

      module ClassMethods

        # Specify options to merge into a render of a valid object, e.g.
        #   valid_render_options :index, serializer: FoobarSerializer
        # For more control, override the `render_(action name)_valid_options` method.
        def valid_render_options(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.action_to_valid_render_options = self.action_to_valid_render_options.clone

          args.each do |action_name|
            if self.action_to_valid_render_options[action_name.to_sym]
              # Set to new merged hash to help avoid subclass inheritance related sharing issues.
              self.action_to_valid_render_options[action_name.to_sym] = self.action_to_valid_render_options[action_name.to_sym].merge(options)
            else
              self.action_to_valid_render_options[action_name.to_sym] = options
            end
          end
        end
      end

      # In initialize we:
      # * guess model name, if unspecified, from controller name
      # * define instance variables containing model name
      # * define the (model_plural_name)_url method, needed if controllers are not in the same module as the models
      # Note: if controller name is not based on model name *and* controller is in different module than model, you'll need to
      # redefine the appropriate method(s) to return urls if needed.
      def initialize
        super

        # if not set, use controller classname
        qualified_controller_name = self.class.name.chomp('Controller')
        @model_class = self.model_class || qualified_controller_name.split('::').last.singularize.constantize

        raise "#{self.class.name} failed to initialize. self.model_class cannot be nil in #{self}" if @model_class.nil?

        @model_singular_name = self.model_singular_name || self.model_class.name.underscore
        @model_plural_name = self.model_plural_name || @model_singular_name.pluralize
        @model_at_plural_name_sym = "@#{@model_plural_name}".to_sym
        @model_at_singular_name_sym = "@#{@model_singular_name}".to_sym
        @model_singular_name_params_sym = "#{@model_singular_name}_params".to_sym

        @action_to_singular_action_model_params_method = {}
        @action_to_plural_action_model_params_method = {}

        underscored_modules_and_underscored_plural_model_name = qualified_controller_name.gsub('::','_').underscore

        # This is a workaround for controllers that are in a different module than the model only works if the controller's base part of the unqualified name in the plural model name.
        # If the model name is different than the controller name, you will need to define methods to return the right urls.
        class_eval "def #{@model_plural_name}_url;#{underscored_modules_and_underscored_plural_model_name}_url;end" unless @model_plural_name == underscored_modules_and_underscored_plural_model_name
        singularized_underscored_modules_and_underscored_plural_model_name = underscored_modules_and_underscored_plural_model_name
        class_eval "def #{@model_singular_name}_url(record);#{singularized_underscored_modules_and_underscored_plural_model_name}_url(record);end" unless @model_singular_name == singularized_underscored_modules_and_underscored_plural_model_name
      end

      def convert_param_value(param_name, param_value)
        param_value
      end
    end
  end
end
