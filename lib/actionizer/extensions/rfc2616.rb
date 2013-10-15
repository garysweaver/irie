module Actionizer
  module Extensions
    # Sets RFC 2616 standard status and location properly in create and update in rendering options.
    # See: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1
    module Rfc2616
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:rfc2616] = '::' + Rfc2616.name

      def options_for_render(record_or_collection)
        logger.debug("Actionizer::Extensions::Rfc2616.options_for_render(#{record_or_collection.inspect})") if Actionizer.debug?
        result = defined?(super) ? super : {}
        unless record_or_collection && record_or_collection.respond_to?(:errors) && record_or_collection.errors.size > 0
          case params[:action]
          when 'create'
            # :created (201) assumes was created, Location header is set with URI to resource, entity contains link to resource,
            # Content-Type header. Optionally may return ETag response header. All we do for now is to set status.
            # This makes the assumption that the location header will be set by something else.
            result = result.merge({status: :created, location: record_or_collection}) if record_or_collection
          when 'update'
            # :no_content (204) response MUST NOT include a message-body, but can return entity-headers. All we do for now is to
            # set status.
            # To make it return 204, do this in your controller: def render_update(record); super(nil); end
            result = result.merge(record_or_collection ? {status: :ok} : {status: :no_content})
          end
        end
        result
      end
    end
  end
end
