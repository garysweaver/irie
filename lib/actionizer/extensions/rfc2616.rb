# Sets RFC 2616 standard status and location properly in create and update in rendering options.
module Actionizer
  module Extensions
    module Rfc2616
      extend ::ActiveSupport::Concern
      Actionizer.available_extensions[:rfc2616] = '::' + Rfc2616.name

      def render_create_valid_options(value)
        (super || {}).merge!({status: :created})
      end

      def render_update_valid_options(value)
        (super || {}).merge!({status: :no_content})
      end
    end
  end
end
