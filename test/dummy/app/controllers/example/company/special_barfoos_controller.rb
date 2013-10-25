module Example
  module Company
    class SpecialBarfoosController < ApplicationController
      
      respond_to :json
      inherit_resources

      actions :all
      extensions :all
      
      # make it use Barfoo class under the hood
      defaults resource_class: Barfoo

      index_query ->(q) {q.where(:status => 2)}

    private

      def permitted_params
        params.permit(:id, :favorite_food)
      end
    end
  end
end
