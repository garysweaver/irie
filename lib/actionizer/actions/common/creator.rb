module Actionizer
  module Actions
    module Common
      module Creator
        extend ::ActiveSupport::Concern

        included do
          include ::Actionizer::Actions::Base
        end

        def new_model_instance(aparams)
          @model_class.new(aparams)
        end
      end
    end
  end
end
