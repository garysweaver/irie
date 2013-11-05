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
end
