module Actionizer
  module Extensions
    module Offset
      extend ::ActiveSupport::Concern
      Actionizer.available_extensions[:offset] = '::' + Offset.name

      included do
        include ::Actionizer::ParamAliases
      end

      def index_filters
        aliased_params(:offset).each {|param_value| @relation.offset!(param_value)}
        super if defined?(super)
      end
    end
  end
end
