module Actionize
  module Actions
    module All
      extend ::ActiveSupport::Concern

      included do
        include ::Actionize::Actions::Index
        include ::Actionize::Actions::Show
        include ::Actionize::Actions::New
        include ::Actionize::Actions::Edit
        include ::Actionize::Actions::Create
        include ::Actionize::Actions::Update
        include ::Actionize::Actions::Destroy
      end
    end
  end
end
