module Actionizer
  module Actions
    module All
      extend ::ActiveSupport::Concern
      Actionizer.available_actions[:all] = '::' + All.name

      included do
        include ::Actionizer::Actions::Index
        include ::Actionizer::Actions::Show
        include ::Actionizer::Actions::New
        include ::Actionizer::Actions::Edit
        include ::Actionizer::Actions::Create
        include ::Actionizer::Actions::Update
        include ::Actionizer::Actions::Destroy
      end
    end
  end
end
