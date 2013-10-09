module Actionizer
  module Extensions
    # Enables CanCan and compatible authorization to be used with actionizer.
    #
    # What's not supported currently: if you use `load_resource` or 
    # `load_and_authorize_resource`, we don't use the instance(s) it sets.
    module Authorizing
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:authorizing] = '::' + Authorizing.name

      # Scope query by .accessible_by(...).
      def query_for_index
        (defined?(super) ? super : @model_class).accessible_by(current_ability, params[:action].to_sym)
      end

      def new_model_instance(aparams)
        authorize! params[:action].to_sym, @model_class
        defined?(super) ? super : @model_class.new(aparams)
      end

      def find_model_instance_with(the_params, first_sym)
        instance = super
        authorize! params[:action].to_sym, instance
      end

    end
  end
end
