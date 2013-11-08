module Example
  module ServiceControllerBehavior
    extend ::ActiveSupport::Concern
    included do
      respond_to :json
      inherit_resources
      ::Irie.register_extension :boolean_params, '::Example::BooleanParams'
    end
  end
end
