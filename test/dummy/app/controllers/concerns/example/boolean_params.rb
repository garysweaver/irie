# example of custom parameter value converter
module Example
  module BooleanParams
    extend ::ActiveSupport::Concern

    TRUE_VALUE = 'true'.freeze
    FALSE_VALUE = 'false'.freeze

    def convert_param_value(param_name, param_value)
      case param_value
      when TRUE_VALUE; true
      when FALSE_VALUE; false
      else; super if defined?(super)
      end
    end
  end
end
