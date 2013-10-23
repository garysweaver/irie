module Actionizer
  module Controller
    extend ::ActiveSupport::Concern

    included do
      class_attribute :available_actions, instance_writer: true
      class_attribute :available_extensions, instance_writer: true

      self.available_actions = ::Actionizer.available_actions || {}
      self.available_extensions = ::Actionizer.available_extensions || {}
    end

    module ClassMethods
      # Shortcut for including one or more action modules. Specify :all to get all.
      # e.g.
      #   include_actions :index, :show, :new, :edit, :create, :update, :destroy
      # You can define more or override in ::Actionizer.available_actions and/or self.available_actions.
      def include_actions(*args)
        args.each do |arg|
          arg_sym = arg.to_sym
          begin
            if arg_sym == :all
              self.available_actions.values.each do |module_class_name|
                include module_class_name.constantize
              end
            elsif module_class_name = self.available_actions[arg.to_sym]
              include module_class_name.constantize
            else
              raise ::Actionizer::ConfigurationError.new "#{arg.inspect} isn't defined in self.available_actions"
            end
          rescue NameError => e
            raise ::Actionizer::ConfigurationError.new "Failed to resolve action module: #{module_class_name}. Ensure the value of self.available_actions[#{arg_sym.inspect}] is a string representing a valid constant. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
      end
      alias include_action include_actions

      # Shortcut for including one or more extension modules. Specify :all to get all.
      # e.g.
      #   include_extensions :count, :distinct
      # You can define more or override in ::Actionizer.available_extensions and/or self.available_extensions.
      def include_extensions(*args)
        args.each do |arg|
          arg_sym = arg.to_sym
          begin
            if arg_sym == :all
              self.available_extensions.values.each do |module_class_name|
                include module_class_name.constantize
              end
            elsif module_class_name = self.available_extensions[arg.to_sym]
              include module_class_name.constantize
            else
              raise ::Actionizer::ConfigurationError.new "#{arg.inspect} isn't defined in self.available_extensions"
            end
          rescue NameError => e
            raise ::Actionizer::ConfigurationError.new "Failed to resolve extension module: #{module_class_name}. Ensure the value of self.available_extensions[#{arg_sym.inspect}] is a string representing a valid constant. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
      end
      alias include_extension include_extensions
    end
  end
end