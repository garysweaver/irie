# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module Actionizer
  module Extensions
    module Authorizing
      extend ::ActiveSupport::Concern

      included do
        include Actionizer::Actions::Base
        
        before_action do |controller|
          authorize! params[:action].to_sym, @model_class
        end
      end
      
    end
  end
end
