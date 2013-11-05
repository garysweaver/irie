module Example
  module Alpha
    class SpecialBarfoosController < ApplicationController
      
      respond_to :json
      inherit_resources

      actions :all
      extensions :all
      
      # make it use Barfoo class under the hood
      defaults resource_class: Barfoo, :collection_name => 'barfoos', :instance_name => 'barfoo'

      index_query ->(q) {q.where(:status => 2)}

    private

      def build_resource_params
        [params.require(:barfoo).permit(:id, :favorite_food)]
      end
    end
  end
end
