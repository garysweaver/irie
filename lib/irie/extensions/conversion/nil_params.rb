module Irie
  module Extensions
    module Conversion
      # Converts the following filter request param values to nil: 'NULL', 'null', 'nil'
      module NilParams
        extend ::ActiveSupport::Concern
        ::Irie.available_extensions[:nil_params] = '::' + NilParams.name

        NILS = ['NULL'.freeze, 'null'.freeze, 'nil'.freeze].to_set

        protected

        # Converts request param values 'NULL', 'null', and 'nil' to nil.
        def convert_param_value(param_name, param_value)
          logger.debug("Irie::Extensions::Conversion::NilParams.convert_param_value(#{param_name.inspect}, #{param_value.inspect})") if Irie.debug?
          param_value = super if defined?(super)
          param_value && NILS.include?(param_value) ? nil : param_value
        end
      
      end
    end
  end
end
