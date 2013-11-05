module Irie
  module Extensions
    # Instead of having to handle @my_model_name.errors in the view, this returns validation errors
    # via rendering { errors: record.errors } for all formats except html.
    module AutorenderErrors
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:autorender_errors] = '::' + AutorenderErrors.name

      included do
        # can't decide which methods to override until they've been defined
        # by the `actions` command, so we wait to include actions module.
        include Actions
      end

      module Actions
        def edit(options={}, &block)
          logger.debug("Irie::Extensions::AutorenderErrors.edit") if Irie.debug?
          return super(options, &block) if request.format.html?
          edit! do |format|
            failure.any { render request.format.symbol => { errors: resource.errors }, status: 422 }
          end
        end if respond_to?(:edit)

        def create(options={}, &block)
          logger.debug("Irie::Extensions::AutorenderErrors.create") if Irie.debug?
          return super(options, &block) if request.format.html?
          create! do |format|
            failure.any { render request.format.symbol => { errors: resource.errors }, status: 422 }
          end
        end if respond_to?(:create)

        def update(options={}, &block)
          logger.debug("Irie::Extensions::AutorenderErrors.update") if Irie.debug?
          return super(options, &block) if request.format.html?
          update! do |format|
            failure.any { render request.format.symbol => { errors: resource.errors }, status: 422 }
          end
        end if respond_to?(:update)

        def destroy(options={}, &block)
          logger.debug("Irie::Extensions::AutorenderErrors.destroy") if Irie.debug?
          return super(options, &block) if request.format.html?
          destroy! do |format|
            failure.any { render request.format.symbol => { errors: resource.errors }, status: 422 }
          end
        end if respond_to?(:destroy)
      end
    end
  end
end
