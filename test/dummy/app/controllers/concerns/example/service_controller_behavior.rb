module Example
  module ServiceControllerBehavior
    extend ::ActiveSupport::Concern
    included do
      respond_to :json
      inherit_resources
      # see config/initializers/irie.rb for autoincludes/extension registration
    end
  end
end
