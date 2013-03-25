require 'cancan'

module RestfulJson
  module Model
    extend ActiveSupport::Concern
    included do
      if defined?(::ActiveModel::ForbiddenAttributesProtection)
        # strong parameters
        include ::ActiveModel::ForbiddenAttributesProtection
      end
      if defined?(::CanCan::ModelAdditions)
        # cancan, depended on by twinturbo's permitters
        include ::CanCan::ModelAdditions
      end
    end
  end
end
