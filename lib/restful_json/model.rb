module RestfulJson
  module Model
    extend ActiveSupport::Concern
    included do
      include ::ActiveModel::ForbiddenAttributesProtection
    end
  end
end
