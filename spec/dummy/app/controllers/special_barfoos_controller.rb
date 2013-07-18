class SpecialBarfoosController < ApplicationController
  include RestfulJson::DefaultController
  
  # make it use Barfoo class under the hood
  self.model_class = Barfoo

  query_for :some_action, is: ->(t,q) {q.where(:status => 2)}
  serialize_action :some_action, with: SimpleBarfooSerializer

  # Returns additional rendering options. By default will massage self.action_to_render_options a little and return that,
  # e.g. if you had used serialize_action to specify an array and each serializer for a specific action, if it is that action,
  # it may return something like: {serializer: MyFooArraySerializer, each_serializer: MyFooSerializer}.
  def additional_render_or_respond_success_options
    if params['minimize']
      result = {}
      result[(single_value_response? ? :serializer : :each_serializer)] = MinimalBarfooSerializer
      result[:serializer] = MinimalBarfooArraySerializer if !single_value_response?
    else
      result = default_additional_render_or_respond_success_options
    end
    result
  end  
end
