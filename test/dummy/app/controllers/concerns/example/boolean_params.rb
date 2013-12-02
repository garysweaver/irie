# example of custom parameter value converter
module Example
  module BooleanParams
    extend ::ActiveSupport::Concern

    TRUE_VALUE = 'true'.freeze
    FALSE_VALUE = 'false'.freeze

    protected

    # Converts request param value(s) 'true' to true and 'false' to false
    def convert_param(param_name, param_value_or_values)
      logger.debug("Example::BooleanParams.convert_param(#{param_name.inspect}, #{param_value_or_values.inspect})") if ::Irie.debug?
      param_value_or_values = super if defined?(super)
      if param_value_or_values.is_a? Array
        param_value_or_values.map {|v| convert_boolean(v)}
      else
        convert_boolean(param_value_or_values)
      end
    end

    private

    def convert_boolean(value)
      case value
      when TRUE_VALUE
        true
      when FALSE_VALUE
        false
      else
        value
      end
    end
  end
end
