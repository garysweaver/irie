module Actionize
  module FunctionParamAliasing
    extend ::ActiveSupport::Concern

    # Looks at Actionize.function_param_names to get the proper request params
    # to check for for the provided param name in @aparams, then returns an array of all
    # values for all matching defined request params. Does *not* convert param
    # value with convert_param_value(...).
    def aliased_params(function_sym)
      if self.function_param_names.include?(function_sym)
        self.function_param_names[function_sym].collect {|param_name| @aparams[param_name]}
      else
        [@aparams[function_sym]]
      end
    end

    # Same as aliased_params(function_sym).first.
    def aliased_param(function_sym)
      aliased_params(function_sym).first
    end
  end
end
