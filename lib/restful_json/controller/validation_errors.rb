# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module RestfulJson
  module Controller
    module ValidationErrors
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      def render_create_invalid(value)
        render_validation_errors(value)
      end

      def render_update_invalid(value)
        render_validation_errors(value)
      end

      def render_validation_errors(value)
        content_type = request.formats.first.to_s.reverse.split('/')[0].split('-')[0].reverse
        # use implicit rendering for html
        return value if request.format.html?
        respond_to do |format|
          format.any { render content_type.to_sym => { errors: value.errors }, status: 422 }
        end
      end

    end
  end
end
