require 'cancan'

module RestfulJson
  module Model
    extend ActiveSupport::Concern
    included do
      # strong parameters
      include ::ActiveModel::ForbiddenAttributesProtection
      # cancan, depended on by twinturbo's permitters
      include ::CanCan::ModelAdditions
    end
  end
end
