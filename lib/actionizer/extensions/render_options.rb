module Actionizer
  module Extensions
    # Allow 
    module RenderOptions
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:render_options] = '::' + RenderOptions.name

      included do
        class_attribute(:action_to_render_options, instance_writer: true) unless self.respond_to? :action_to_render_options
        class_attribute(:action_to_valid_render_options, instance_writer: true) unless self.respond_to? :action_to_valid_render_options
        class_attribute(:action_to_invalid_render_options, instance_writer: true) unless self.respond_to? :action_to_invalid_render_options

        self.action_to_render_options ||= {}
        self.action_to_valid_render_options ||= {}
        self.action_to_invalid_render_options ||= {}
      end

      module ClassMethods

        # Specify options to merge into a render of a record, e.g.
        #   render_options :index, serializer: FoobarSerializer
        # For more control, override the `render_(action name)` method.
        def render_options(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.action_to_render_options = self.action_to_render_options.clone

          args.each do |action_name|
            if self.action_to_render_options[action_name.to_sym]
              # Set to new merged hash to help avoid subclass inheritance related sharing issues.
              self.action_to_render_options[action_name.to_sym] = self.action_to_render_options[action_name.to_sym].merge(options)
            else
              self.action_to_render_options[action_name.to_sym] = options
            end
          end
        end

        # Specify options to merge into a render of a record that does not respond to `.errors`, e.g.
        #   valid_render_options :index, serializer: FoobarSerializer
        # For more control, override the `render_(action name)` method.
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

        # Specify options to merge into a render of a record that responds to `.errors`, e.g.
        #   invalid_render_options :index, serializer: FoobarSerializer
        # For more control, override the `render_(action name)` method.
        def invalid_render_options(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.action_to_invalid_render_options = self.action_to_invalid_render_options.clone

          args.each do |action_name|
            if self.action_to_invalid_render_options[action_name.to_sym]
              # Set to new merged hash to help avoid subclass inheritance related sharing issues.
              self.action_to_invalid_render_options[action_name.to_sym] = self.action_to_invalid_render_options[action_name.to_sym].merge(options)
            else
              self.action_to_invalid_render_options[action_name.to_sym] = options
            end
          end
        end
      end

      def options_for_render(record_or_collection)
        result = defined?(super) ? super : {}
        (result ||= {}).merge!(self.action_to_render_options[params[:action].to_sym] || {})
        if record_or_collection.respond_to?(:errors) && record_or_collection.errors.size > 0
          result.merge!(self.action_to_invalid_render_options[params[:action].to_sym] || {})
        else
          result.merge!(self.action_to_valid_render_options[params[:action].to_sym] || {})
        end
      end
    end
  end
end
