module Irie
  module Extensions
    # Standard rendering of index page count in all formats except html so you don't need views for them.
    module AutorenderCount
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:autorender_count] = '::' + AutorenderCount.name

      protected
      
      def autorender_count(options={}, &block)
        logger.debug("Irie::Extensions::AutorenderCount.autorender_count") if Irie.debug?
        render request.format.symbol => { count: @count }, status: 200, layout: false
      end
      
    end
  end
end
