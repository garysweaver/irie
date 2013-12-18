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
require 'irie/extensions/smart_layout'

class ::ActionController::Base
  extend ::Irie::ClassMethods
end

# rails 3.2 support
unless [].respond_to?(:deep_dup)
  class Object
    def deep_dup
      duplicable? ? dup : self
    end
  end

  class Array
    def deep_dup
      map { |it| it.deep_dup }
    end
  end

  class Hash
    def deep_dup
      each_with_object(dup) do |(key, value), hash|
        hash[key.deep_dup] = value.deep_dup
      end
    end
  end
end
