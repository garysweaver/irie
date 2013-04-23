module RestfulJson
  module DefaultController
    extend ::ActiveSupport::Concern

    included do
      include ::ActionController::Serialization
      include ::ActionController::StrongParameters
      include ::TwinTurbo::Controller
      include ::RestfulJson::Controller
    end
  end
end
