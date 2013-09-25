module Actionizer
  module Extensions
    # Instead of having to handle @my_model_name.errors in the view, this returns validation errors
    # via rendering { errors: record.errors } for all formats except html.
    module AutorenderErrors
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:autorender_errors] = '::' + AutorenderErrors.name

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
