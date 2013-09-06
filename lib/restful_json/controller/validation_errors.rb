# Instead of having to handle @my_model_name.errors in the view, this returns validation errors
# via rendering { errors: record.errors } for all formats except html.
module RestfulJson
  module Controller
    module ValidationErrors
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      def render_create_invalid(record)
        render_validation_errors(record)
      end

      def render_update_invalid(record)
        render_validation_errors(record)
      end

      def render_validation_errors(record)
        content_type = request.formats.first.to_s.reverse.split('/')[0].split('-')[0].reverse
        # use implicit rendering for html
        return record if request.format.html?
        respond_to do |format|
          format.any { render content_type.to_sym => { errors: record.errors }, status: 422 }
        end
      end

    end
  end
end
