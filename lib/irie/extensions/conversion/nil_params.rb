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
        def convert_param_values(param_name, param_values)
          logger.debug("Irie::Extensions::Conversion::NilParams.convert_param_values(#{param_name.inspect}, #{param_values.inspect})") if Irie.debug?
          param_values = super if defined?(super)
          param_values && NILS.include?(param_values) ? nil : param_values
        end
      
      end
    end
  end
end
