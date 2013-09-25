module Actionizer
  # If there is a problem with class load related to includes:
  #   require 'actionizer/controller_debugging'
  #   extend ::Actionizer::ControllerDebugging
  #   # Ensure this comes after all relevant includes.
  #   output_actionizer_debugging_info
  # And if there is a problem with instance methods/behavior related to includes:
  #   require 'actionizer/controller_debugging'
  #   include ::Actionizer::ControllerDebugging
  #   def initialize(*args)
  #     output_actionizer_debugging_info
  #   end
  module ControllerDebugging
    # Output Actionizer related debugging info to console.
    def output_actionizer_debugging_info
      puts "\n\n#{self} Actionizer config:\n\n"
      if self.is_a?(Class)
        the_config_desc = 'self'
        the_config_class = the_self_class = self
      else
        the_config_desc = 'self.class'
        the_config_class = the_self_class = self.class
      end
      unless the_self_class.respond_to(:available_actions) && the_self_class.respond_to(:available_extensions)
        the_config_desc = '::Actionizer'
        the_config_class = ::Actionizer
      end
      puts "#{the_config_desc}.available_actions:\n\n#{the_config_class.available_actions.collect{|k,v|"#{k.inspect} = #{v.inspect}"}.join("\n")}\n\n"
      puts "#{the_config_desc}.available_extensions:\n\n#{the_config_class.available_extensions.collect{|k,v|"#{k.inspect} = #{v.inspect}"}.join("\n")}\n\n"
      all_registered_actionizer_modules = (the_config_class.available_actions.values + the_config_class.available_extensions.values).compact.uniq.collect do |m|
        begin
          m = m.is_a?(String) ? m.constantize : m
          raise unless m.is_a?(Module)
        rescue => e
          puts "Actionizer config specifies invalid module: #{m}"
        end
        m
      end
      registered_actionizer_ancestors = the_self_class.ancestors.select {|a|all_registered_actionizer_modules.include?(a)}
      puts "#{the_self_class}.ancestors in #{the_config_desc}.available_actions/#{the_config_desc}.available_extensions:\n\n#{registered_actionizer_ancestors.collect{|s|s.to_s}.join("\n")}\n\n"

      puts "(The following may help you identify methods that are defined in Actionizer includes. Ensure `super if defined?(super)` is done for methods that should support chaining.)\n\n"

      puts "Instance methods in #{the_self_class} and Actionizer-registered ancestors, excluding methods only defined in #{the_self_class}:\n\n"
      instance_method_inheritance_chain = {}
      the_self_class.instance_methods(false).each do |m|
        (instance_method_inheritance_chain[m] ||= []) << the_self_class
      end
      registered_actionizer_ancestors.each do |a|
        a.instance_methods(false).each do |m|
          (instance_method_inheritance_chain[m] ||= []) << a unless instance_method_inheritance_chain[m].try(:includes?, a)
        end
      end
      instance_method_inheritance_chain.reject!{|k,v| v.first == the_self_class}
      puts "#{instance_method_inheritance_chain.collect{|k,v|"#{k.inspect} = #{v.collect{|a|a.to_s}.join(", ")}"}.sort.join("\n")}\n\n"

    rescue => e
      puts "output_actionizer_debugging_info failed: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
end
