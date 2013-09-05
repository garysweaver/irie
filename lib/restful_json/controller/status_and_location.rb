# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module RestfulJson
  module Controller
    module StatusAndLocation
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      def render_create_valid_options(value)
        (super || {}).merge!({status: :created, location: value})
      end

      def render_update_valid_options(value)
        (super || {}).merge!({status: :no_content})
      end

    end
  end
end
