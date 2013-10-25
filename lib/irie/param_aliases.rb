module Irie
  module ParamAliases
    extend ::ActiveSupport::Concern

    # Looks at ::Irie.function_param_names to get the proper request params
    # to check for for the provided param name in params, then returns an array of all
    # values for all matching defined request params. Does *not* convert param
    # value with convert_param_value(...).
    def aliased_params(function_sym)
      logger.debug("Irie::ParamAliases.aliased_params(#{function_sym.inspect})") if Irie.debug?
      if self.function_param_names.key?(function_sym)
        self.function_param_names[function_sym].select {|v| permitted_params.key?(v)}.collect {|param_name| permitted_params[param_name]}
      else
        permitted_params.key?(function_sym) ? [permitted_params[function_sym]] : []
      end
    end

    # Same as aliased_params(function_sym).first.
    def aliased_param(function_sym)
      logger.debug("Irie::ParamAliases.aliased_param(#{function_sym.inspect})") if Irie.debug?
      aliased_params(function_sym).first
    end
  end
end
