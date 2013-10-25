module Irie
  module Extensions
    # Instead of having to handle @my_model_name.errors in the view, this returns validation errors
    # via rendering { errors: record.errors } for all formats except html.
    module AutorenderErrors
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:autorender_errors] = '::' + AutorenderErrors.name

      def edit
        logger.debug("Irie::Extensions::AutorenderErrors.edit(#{count.inspect})") if Irie.debug?
        return super if !get_resource_ivar.respond_to?(:errors) || request.format.html?
        index! do |format|
          format.any { render request.format.symbol => { errors: record_or_collection.errors }, status: 422 }
        end
      end if respond_to?(:edit)

      def create
        logger.debug("Irie::Extensions::AutorenderErrors.create(#{count.inspect})") if Irie.debug?
        return super if !get_resource_ivar.respond_to?(:errors) || request.format.html?
        index! do |format|
          format.any { render request.format.symbol => { errors: record_or_collection.errors }, status: 422 }
        end
      end if respond_to?(:create)

      def update
        logger.debug("Irie::Extensions::AutorenderErrors.update(#{count.inspect})") if Irie.debug?
        return super if !get_resource_ivar.respond_to?(:errors) || request.format.html?
        index! do |format|
          format.any { render request.format.symbol => { errors: record_or_collection.errors }, status: 422 }
        end
      end if respond_to?(:update)

      def destroy
        logger.debug("Irie::Extensions::AutorenderErrors.destroy(#{count.inspect})") if Irie.debug?
        return super if !get_resource_ivar.respond_to?(:errors) || request.format.html?
        index! do |format|
          format.any { render request.format.symbol => { errors: record_or_collection.errors }, status: 422 }
        end
      end if respond_to?(:destroy)
      
    end
  end
end
