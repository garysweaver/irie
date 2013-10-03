module Actionizer
  module Extensions
    # Sets RFC 2616 standard status and location properly in create and update in rendering options.
    module Rfc2616
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:rfc2616] = '::' + Rfc2616.name

      def options_for_render(record_or_collection)
        result = defined?(super) ? super : {}
        if record_or_collection && !(record_or_collection.respond_to?(:errors) && record_or_collection.errors.size > 0)
          case params[:action]
          when 'create'
            result = result.merge({status: :created})
          when 'update'
            result = result.merge({status: :no_content})
          end
        end
        result
      end
    end
  end
end
