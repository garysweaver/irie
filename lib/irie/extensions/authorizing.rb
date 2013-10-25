module Irie
  module Extensions
    # Enables CanCan and compatible authorization to be used with irie.
    #
    # What's not supported currently: if you use `load_resource` or 
    # `load_and_authorize_resource`, we don't use the instance(s) it sets.
    module Authorizing
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:authorizing] = '::' + Authorizing.name

      # Scope query by .accessible_by(...).
      def begin_of_association_chain
        logger.debug("Irie::Extensions::Extensions.query_for_index") if Irie.debug?
        (defined?(super) ? super : resource_class).accessible_by(current_ability, params[:action].to_sym)
      end

    end
  end
end
