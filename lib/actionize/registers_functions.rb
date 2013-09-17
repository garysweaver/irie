require 'active_support/hash_with_indifferent_access'

module Actionize
  module RegistersFunctions
    extend ::ActiveSupport::Concern

    included do
      class_attribute :actionize_functions, instance_writer: true

      self.actionize_functions ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    module ClassMethods
      # Register to call the block or method as part of one or more function groups.
      # e.g.
      #   function_for :index_filters, :after_index_filters name: 'Hello::Function' do; puts "hello #{some_local_var}"; nil; end
      # or:
      #   function_for :index_filters, :after_index_filters name: 'Hello::Function', method: :some_method
      # To break out early from a function and force the action method to return, use function_return, e.g.
      #   function_for :index_filters, name: 'Hello::Function' do
      #     function_return 5
      #   end
      def function_for(*args)
        options = args.extract_options!

        raise "Please supply :name option in function_for with something that describes the function, e.g. function_for :index_filters, name: Your::Function::Class::Name {puts 'Logged'}" unless options[:name]
        raise "Please supply block or :method option in function_for" unless block_given? || options[:method]
        raise "Cannot supply both block and :method option in function_for" if block_given? && options[:method]

        args.each do |arg|
          f_hash = (self.actionize_functions[arg] ||= {})
          if block_given?
            f_hash[options[:name]] = -> { yield }
          else
            f_hash[options[:name]] = options[:method].to_sym
          end
        end
      end

      # In the initializer of the concern that calls the procs, be sure to either 
      # define at least one block to be name or just define it without a block, e.g.:
      #   function_groups :index_filters, :after_index_filters
      def function_groups(*args)
        args.each {|arg| self.actionize_functions[arg] ||= {}}
      end
      alias function_group function_groups
    end

    def function_return(value)
      @actionize_function_result = value
      throw :function_return
    end
  end
end
