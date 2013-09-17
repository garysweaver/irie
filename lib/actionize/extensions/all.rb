module Actionize
  module Extensions
    module All
      extend ::ActiveSupport::Concern

      included do
        include ::Actionize::Extensions::Authorizing
        include ::Actionize::Extensions::ConvertingNullParamValuesToNil
        include ::Actionize::Extensions::RenderingCountsAutomaticallyForNonHtml
        include ::Actionize::Extensions::RenderingValidationErrorsAutomaticallyForNonHtml
        include ::Actionize::Extensions::UsingStandardRestRenderOptions
      end
    end
  end
end
