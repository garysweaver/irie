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
        logger.debug("Actionizer::Extensions::Extensions.query_for_index") if Actionizer.debug?
        (defined?(super) ? super : resource_class).accessible_by(current_ability, params[:action].to_sym)
      end

      def new_model_instance(aparams)
        logger.debug("Actionizer::Extensions::Extensions.new_model_instance(#{aparams.inspect})") if Actionizer.debug?
        authorize! params[:action].to_sym, resource_class
        defined?(super) ? super : resource_class.new(aparams)
      end

      def find_model_instance_with(the_params, first_sym)
        logger.debug("Actionizer::Extensions::Extensions.find_model_instance_with(#{the_params.inspect}, #{first_sym.inspect})") if Actionizer.debug?
        instance = super
        authorize! params[:action].to_sym, instance
      end

    end
  end
end
