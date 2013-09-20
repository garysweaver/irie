module Actionizer
  module FunctionParamAliasing
    extend ::ActiveSupport::Concern

    # Looks at Actionizer.function_param_names to get the proper request params
    # to check for for the provided param name in params, then returns an array of all
    # values for all matching defined request params. Does *not* convert param
    # value with convert_param_value(...).
    def aliased_params(function_sym)
      if self.function_param_names.key?(function_sym)
        self.function_param_names[function_sym].select {|v| params.key?(v)}.collect {|param_name| aparams[param_name]}
      else
        aparams.key?(function_sym) ? [aparams[function_sym]] : []
      end
    end

    # Same as aliased_params(function_sym).first.
    def aliased_param(function_sym)
      aliased_params(function_sym).first
    end
  end
end
