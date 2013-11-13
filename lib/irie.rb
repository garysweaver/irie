require 'irie/version'
require 'irie/configuration_error'
require 'irie/config'
require 'irie/class_methods'
require 'irie/param_aliases'
require 'irie/extensions/autorender_count'
require 'irie/extensions/params_to_joins'
require 'irie/extensions/conversion/nil_params'
require 'irie/extensions/count'
require 'irie/extensions/index_query'
require 'irie/extensions/limit'
require 'irie/extensions/offset'
require 'irie/extensions/order'
require 'irie/extensions/paging/autorender_page_count'
require 'irie/extensions/paging'
require 'irie/extensions/param_filters'
require 'irie/extensions/query_filter'
require 'irie/extensions/query_includes'

class ActionController::Base
  extend Irie::ClassMethods
#
#  alias_method :orig_respond_with, :respond_with
#  def respond_with(*args, &block)
#    logger.debug("respond with called with #{args.inspect}") if Irie.debug?
#    args = args.collect do |arg|
#      if arg.is_a?(ActiveRecord::Relation)
#        if params[:action] == 'index'
#          arg.to_a
#        else
#          arg.to_a.last
#        end
#      else
#        arg
#      end
#    end
#    
#    logger.debug("converted to #{args.inspect} and calling original respond_with") if Irie.debug?
#    
#    orig_respond_with(*args, &block)
#  end
#
end

#class ActionController::Responder
#  def default_render
#    if @default_response
#      @default_response.call(options)
#    else
#      @action == 'index' || (@resources && @resources.size > 1) ? controller.default_render(@resources, options) : controller.default_render(@resource, options)
#    end
#  end
#end
