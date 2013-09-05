# Converts the following filter request param values to nil: 'NULL', 'null', 'nil'
module RestfulJson
  module Controller
    module NilParamValues
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      NILS = ['NULL'.freeze, 'null'.freeze, 'nil'.freeze].to_set

      # Converts request param values 'NULL', 'null', and 'nil' to nil.
      def convert_request_param_value_for_filtering(attr_sym, value)
        value = super || value
        value && NILS.include?(value) ? nil : value
      end

    end
  end
end
