require 'restful_json/version'
require 'restful_json/config'
require 'twinturbo/application_permitter'
require 'twinturbo/controller'
require 'restful_json/base_controller'
require 'restful_json/controller'
require 'restful_json/default_controller'

ActiveSupport::Dependencies.autoload_paths << "#{Rails.root}/app/permitters" unless ActiveSupport::Dependencies.autoload_paths.include?("#{Rails.root}/app/permitters")