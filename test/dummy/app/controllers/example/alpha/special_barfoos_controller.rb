module Example
  module Alpha
    class SpecialBarfoosController < ApplicationController
      
      respond_to :json
      inherit_resources

      actions :all
      extensions :all
      
      # make it use Barfoo class under the hood
      defaults resource_class: Barfoo

      index_query ->(q) {q.where(:status => 2)}

    private

      #def permitted_params
      #  params.permit(barfoo: [:id, :favorite_food])
      #end

      def build_resource_params
        [params.require(:barfoo).permit(:id, :favorite_food)]
      end
    end
  end
end
