module Irie
  module Extensions
    # Standard rendering of index page count in all formats except html so you don't need views for them.
    module AutorenderCount
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:autorender_count] = '::' + AutorenderCount.name

      def autorender_count(options={}, &block)
        logger.debug("Irie::Extensions::AutorenderCount.autorender_count") if Irie.debug?
        index! do |format|
          format.any { render request.format.symbol => { count: @count }, status: 200 }
        end
      end
      
    end
  end
end
