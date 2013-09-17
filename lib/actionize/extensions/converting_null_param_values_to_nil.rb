# Converts the following filter request param values to nil: 'NULL', 'null', 'nil'
module Actionize
  module Extensions
    module ConvertingNullParamValuesToNil
      extend ::ActiveSupport::Concern

      NILS = ['NULL'.freeze, 'null'.freeze, 'nil'.freeze].to_set

      # Converts request param values 'NULL', 'null', and 'nil' to nil.
      def convert_param_value(param_name, param_value)
        param_value = super || param_value
        param_value && NILS.include?(param_value) ? nil : param_value
      end

    end
  end
end
