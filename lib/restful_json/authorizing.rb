# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module RestfulJson
  module Authorizing
    extend ::ActiveSupport::Concern

    included do
      before_action do |controller|
        #TODO: must we rescue and respond with right http code here?
        authorize! params[:action].to_sym, @model_class
      end
    end
  end
end
