module Actionize
  module Controller
    extend ::ActiveSupport::Concern

    included do
      class_attribute :available_actions, instance_writer: true
      class_attribute :available_extensions, instance_writer: true
      class_attribute :available_functions, instance_writer: true

      self.available_actions = Actionize.available_actions || {}
      self.available_extensions = Actionize.available_extensions || {}
      self.available_functions = Actionize.available_functions || {}
    end

    module ClassMethods
      # Shortcut for including one or more action modules.
      # e.g.
      #   include_actions :index, :show, :new, :edit, :create, :update, :destroy
      # You can define more or override in Actionize.available_actions and/or self.available_actions.
      def include_actions(*args)
        args.each do |arg|
          raise "#{arg.inspect} isn't defined in self.available_actions" unless self.available_actions[arg.to_sym]
          include self.available_actions[arg.to_sym].constantize
        end
      end
      alias include_action include_actions

      # Shortcut for including one or more extension modules.
      # e.g.
      #   include_extensions :using_standard_rest_render_options
      # You can define more or override in Actionize.available_extensions and/or self.available_extensions.
      def include_extensions(*args)
        args.each do |arg|
          raise "#{arg.inspect} isn't defined in self.available_extensions" unless self.available_extensions[arg.to_sym]
          include self.available_extensions[arg.to_sym].constantize
        end
      end
      alias include_extension include_extensions

      # Shortcut for including one or more function modules.
      # e.g.
      #   include_functions :param_filters, :count
      # You can define more or override in Actionize.available_functions and/or self.available_functions.
      def include_functions(*args)
        args.each do |arg|
          raise "#{arg.inspect} isn't defined in self.available_functions" unless self.available_functions[arg.to_sym]
          include self.available_functions[arg.to_sym].constantize
        end
      end
      alias include_function include_functions
    end
  end
end