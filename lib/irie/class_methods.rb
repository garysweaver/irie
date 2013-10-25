module Irie
  module ClassMethods

    def extensions(*extension_syms)
      ::Irie::CONTROLLER_OPTIONS.each do |key|
        class_attribute key, instance_writer: true unless respond_to?(key)
        self.send("#{key}=".to_sym, ::Irie.send(key)) unless self.send(key.to_sym)
      end

      self.autoincludes.keys.each do |action_sym|
        if instance_methods.include?(action_sym)
          autoloading_extensions = self.autoincludes[action_sym]
          if autoloading_extensions && autoloading_extensions.size > 0
            manual_extensions *autoloading_extensions
            extension_syms -= autoloading_extensions
          end
        end
      end
      
      manual_extensions extension_syms
    end

  private

    def manual_extensions(*extension_syms)      
      # load requested extensions
      extension_syms.flatten.collect {|es| es.to_sym}.compact.each do |arg_sym|
        if arg_sym == :all
          self.available_extensions.each do |key, module_class_name|
            begin
              include module_class_name.constantize
            rescue NameError => e
              raise ::Irie::ConfigurationError.new "Failed to resolve extension module '#{module_class_name}' with key #{key.inspect} in self.available_extensions when including all extensions. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          end
        elsif module_class_name = self.available_extensions[arg_sym]
          begin
            include module_class_name.constantize
          rescue NameError => e
            raise ::Irie::ConfigurationError.new "Failed to resolve extension module '#{module_class_name}' with key #{arg_sym.inspect} in self.available_extensions. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
          end      
        else
          raise ::Irie::ConfigurationError.new "#{arg_sym.inspect} isn't defined in self.available_extensions"
        end
      end
    end
  end
end
