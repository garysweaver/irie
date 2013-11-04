module Irie
  module ParamAliases
    extend ::ActiveSupport::Concern

    protected

    # Looks at ::Irie.function_param_names to get the proper request params
    # to check for for the provided param name in params, then returns an array of all
    # values for all matching defined request params. Does *not* convert param
    # value with convert_param_value(...).
    def aliased_param_values(function_sym)
      logger.debug("Irie::ParamAliases.aliased_param_values(#{function_sym.inspect})") if Irie.debug?
      if self.function_param_names.key?(function_sym)
        self.function_param_names[function_sym].select {|v| params.key?(v)}.collect {|param_name| params[param_name]}
      else
        params.key?(function_sym) ? Array.wrap(params[function_sym]) : []
      end
    end

    # Same as aliased_param_values(function_sym).first.
    def first_aliased_param_value(function_sym)
      logger.debug("Irie::ParamAliases.first_aliased_param_value(#{function_sym.inspect})") if Irie.debug?
      aliased_param_values(function_sym).first
    end
  end
end
