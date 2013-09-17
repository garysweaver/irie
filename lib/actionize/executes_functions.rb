module Actionize
  module ExecutesFunctions
    extend ::ActiveSupport::Concern

    # Calls functions in specified function groups. If :function_return is
    # thrown in the function, stops execution chain. Returns
    # @actionize_function_result, e.g.:
    #   short_circuit_result = execute_functions(:index_filters, :after_index_filters)
    #   return short_circuit_result if short_circuit_result
    def execute_functions(*args)
      args.extract_options!

      catch :function_return do
        args.each do |arg|
          f_hash = self.actionize_functions[arg.to_sym]
          raise "#{arg.to_sym} is not a valid function group" unless f_hash
          puts "#{self.class}.#{params[:action]} has function hash #{f_hash.inspect}" 
          f_hash.each do |label, lambda_or_method_sym|
            puts "#{self.class}.#{params[:action]} calling function #{label}"
            lambda_or_method_sym.is_a?(Symbol) ? __send__(lambda_or_method_sym) : lambda_or_method_sym.call
          end
        end          
      end
      @actionize_function_result
    end
  end
end
