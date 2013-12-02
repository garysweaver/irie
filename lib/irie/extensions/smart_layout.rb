module Irie
  module Extensions
    # Specify layout: false unless request.format.html?
    module SmartLayout
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:smart_layout] = '::' + SmartLayout.name

      included do
        include ::Irie::ParamAliases
      end
      
      def index(options={}, &block)
        logger.debug("Irie::Extensions::NoLayout.index") if ::Irie.debug?
        options.merge!({layout: false}) unless request.format.html?
        super(options, &block)
      end

    end
  end
end
