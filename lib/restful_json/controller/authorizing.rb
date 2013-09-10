# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module RestfulJson
  module Controller
    module Authorizing
      extend ::ActiveSupport::Concern

      include ::RestfulJson::Controller

      included do
        before_action do |controller|
          authorize! params[:action].to_sym, @model_class
        end
      end
    end
  end
end
