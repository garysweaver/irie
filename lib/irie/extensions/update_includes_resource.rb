module Irie
  module Extensions
    # Makes the 'update' action return the resource.
    module UpdateIncludesResource
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:update_includes_resource] = '::' + UpdateIncludesResource.name

      if respond_to?(:update)
        def update(options={}, &block)
          logger.debug("Irie::Extensions::IncludeResource.update") if Irie.debug?
          # rcontroller by default won't return entity with update per RFC 2616: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1
          # but if this is included, we tell it to define a location to return the resource on update.
          options[:location] ||= resource_url
          return super(options, &block)
        end
      end

    end
  end
end
