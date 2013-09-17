# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module Actionize
  module Extensions
    module Authorizing
      extend ::ActiveSupport::Concern

      include Actionize::Actions::Base

      included do
        before_action do |controller|
          authorize! params[:action].to_sym, @model_class
        end
      end
      
    end
  end
end
