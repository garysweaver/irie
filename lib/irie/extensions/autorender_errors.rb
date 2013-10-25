module Irie
  module Extensions
    # Instead of having to handle @my_model_name.errors in the view, this returns validation errors
    # via rendering { errors: record.errors } for all formats except html.
    module AutorenderErrors
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:autorender_errors] = '::' + AutorenderErrors.name

      def perform_render(record_or_collection, options = nil)
        logger.debug("Irie::Extensions::AutorenderErrors.perform_render(#{record_or_collection.inspect}, #{options.inspect})") if Irie.debug?
        if !request.format.html? && record_or_collection.respond_to?(:errors) && record_or_collection.errors.size > 0
          respond_to do |format|
            format.any { render request.format.symbol => { errors: record_or_collection.errors }, status: 422 }
          end
        else
          defined?(super) ? super : get_collection_ivar
        end
      end
      
    end
  end
end
