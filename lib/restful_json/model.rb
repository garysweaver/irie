module RestfulJson
  module Model
    extend ActiveSupport::Concern

    included do
      include ::ActiveModel::ForbiddenAttributesProtection
    end

    module ClassMethods
    end

  end
end
