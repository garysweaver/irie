module Actionizer
  module Controller
    extend ::ActiveSupport::Concern

    included do
      class_attribute :available_actions, instance_writer: true
      class_attribute :available_extensions, instance_writer: true

      self.available_actions = Actionizer.available_actions || {}
      self.available_extensions = Actionizer.available_extensions || {}
    end

    module ClassMethods
      # Shortcut for including one or more action modules.
      # e.g.
      #   include_actions :index, :show, :new, :edit, :create, :update, :destroy
      # You can define more or override in Actionizer.available_actions and/or self.available_actions.
      def include_actions(*args)
        args.each do |arg|
          raise "#{arg.inspect} isn't defined in self.available_actions" unless self.available_actions[arg.to_sym]
          begin
            include self.available_actions[arg.to_sym].constantize
          rescue NameError => e
            raise "Failed to resolve action module. Check Actionizer/self.available_actions[#{arg.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
      end
      alias include_action include_actions

      # Shortcut for including one or more extension modules.
      # e.g.
      #   include_extensions :using_standard_rest_render_options
      # You can define more or override in Actionizer.available_extensions and/or self.available_extensions.
      def include_extensions(*args)
        args.each do |arg|
          raise "#{arg.inspect} isn't defined in self.available_extensions" unless self.available_extensions[arg.to_sym]
          begin
            include self.available_extensions[arg.to_sym].constantize
          rescue NameError => e
            raise "Failed to resolve extension module. Check Actionizer/self.available_extensions[#{arg.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
      end
      alias include_extension include_extensions
    end
  end
end