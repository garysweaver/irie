# Sets standard status and location properly in create and update in rendering options.
module Actionizer
  module Extensions
    module UsingStandardRestRenderOptions
      extend ::ActiveSupport::Concern

      def render_create_valid_options(value)
        (super || {}).merge!({status: :created})
      end

      def render_update_valid_options(value)
        (super || {}).merge!({status: :no_content})
      end
      
    end
  end
end
