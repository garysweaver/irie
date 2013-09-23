# Allows the ability to return distinct records in the index query.
module Actionizer
  module Extensions
    module Distinct
      extend ::ActiveSupport::Concern
      Actionizer.available_extensions[:distinct] = '::' + Distinct.name

      included do
        include ::Actionizer::ParamAliases
      end

      def index_filters
        @relation.distinct! if aliased_param(:distinct)
        super if defined?(super)
      end
    end
  end
end
