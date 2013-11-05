class BarfoosController < ApplicationController

  respond_to :json
  inherit_resources

  actions :all
  extensions :count, :autorender_count, :paging, :autorender_page_count
  
  index_query ->(q) {q.where(:status => 2)}
  query_includes :foo

  def resource
    b = super
    b.errors.add(:base, "sample #{params[:action]} errors") if $resource_has_errors
    set_resource_ivar b
  end

private

  def build_resource_params
    [params.require(:barfoo).permit(:id, :favorite_food)]
  end
end
