# Enables CanCan and compatible authR to be used with actionizer implemented
# actions via `@relation.accessible_by.accessible_by(current_ability, :index)`
# or `authorize! params[:action].to_sym, @relation`.
#
# What's not supported currently: if you use `load_resource` or 
# `load_and_authorize_resource`, we don't use the instance(s) it sets.
module Actionizer
  module Extensions
    module Authorizing
      extend ::ActiveSupport::Concern

      # It is assumed that module includes will be done in such an order that
      # this method is executed before all others in the chain except the
      # one in the index module.
      def query_for_index
        # note: this does not call super on-purpose. See doc above.
        @model_class.accessible_by(current_ability, params[:action].to_sym)
      end

    private

      def find_model_instance_with(aparams, first_sym)
        authorize! params[:action].to_sym, nil
        instance = super
        authorize! params[:action].to_sym, instance
      end

    end
  end
end
