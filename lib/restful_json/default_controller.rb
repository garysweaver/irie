# The Rails 3.x "would you like fries with that" module that includes:
#  * ActionController::Serialization
#  * ActionController::StrongParameters
#  * ActionController::Permittance
#  * RestfulJson::Controller
#
# Instead of using this, please consider implementing your own module to include these modules so you have more control over it.
# And in Rails 4+, don't use this, because ActionController::StrongParameters might already be included.
module RestfulJson
  module DefaultController
    extend ::ActiveSupport::Concern

    included do
      include ::ActionController::Serialization
      include ::ActionController::StrongParameters
      include ::ActionController::Permittance
      include ::RestfulJson::Controller
    end
  end
end
