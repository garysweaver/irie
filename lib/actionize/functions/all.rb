module Actionize
  module Functions
    module All
      extend ::ActiveSupport::Concern

      included do
        include ::Actionize::Functions::Count
        include ::Actionize::Functions::CustomQuery
        include ::Actionize::Functions::Distinct
        include ::Actionize::Functions::Limit
        include ::Actionize::Functions::Offset
        include ::Actionize::Functions::Order
        include ::Actionize::Functions::Paging
        include ::Actionize::Functions::ParamFilters
        include ::Actionize::Functions::QueryFilter
        include ::Actionize::Functions::QueryIncludes
      end
    end
  end
end
