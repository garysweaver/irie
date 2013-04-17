module RestfulJson
  module DefaultController
    extend ::ActiveSupport::Concern

    included do
      include ::ActionController::Serialization
      include ::ActionController::StrongParameters
      include ::TwinTurbo::Controller
      include ::RestfulJson::Controller
      
      rescue_from Exception, :with => :render_error
      rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
      rescue_from ActionController::RoutingError, :with => :render_not_found
      rescue_from ActionController::UnknownController, :with => :render_not_found
      rescue_from AbstractController::ActionNotFound, :with => :render_not_found
    end
  end
end
