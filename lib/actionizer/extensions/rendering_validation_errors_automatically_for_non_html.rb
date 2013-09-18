# Instead of having to handle @my_model_name.errors in the view, this returns validation errors
# via rendering { errors: record.errors } for all formats except html.
module Actionizer
  module Extensions
    module RenderingValidationErrorsAutomaticallyForNonHtml
      extend ::ActiveSupport::Concern

      def render_create_invalid(record)
        render_validation_errors(record)
      end

      def render_update_invalid(record)
        render_validation_errors(record)
      end

      def render_validation_errors(record)
        # use implicit rendering for html
        return record if request.format.html?
        respond_to do |format|
          format.any { render request.format.symbol => { errors: record.errors }, status: 422 }
        end
      end
      
    end
  end
end
