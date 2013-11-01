ENV["RAILS_ENV"] = "test"

$:.unshift File.dirname(__FILE__)

#unless ENV['CI']
#  require 'simplecov'
#  SimpleCov.start do
#    add_filter '/gemfiles/'
#    add_filter '/spec/'
#    add_filter '/temp/'
#  end
#end

require 'dummy/config/environment'
require 'dummy/db/schema'
require 'rails/test_help'

#$:.unshift File.expand_path('../support', __FILE__)
#Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

puts "Testing Rails v#{Rails.version}"
Rails.backtrace_cleaner.remove_silencers!

require 'irie'
Irie.debug = true
ActiveRecord::Base.logger = Logger.new(STDOUT)
#ActiveRecord::Base.logger = Logger::DEBUG
ActionController::Base.logger = Logger.new(STDOUT)
ActionController::Base.logger.level = Logger::DEBUG

# important: we want to ensure that if there is any problem with one class load affecting another
# (e.g. with helper_method usage for url and path helpers) that we expose that by loading all
# controller bodies in the beginning via eager loading everything
Rails.application.eager_load!

# Debug routes in Appraisals, since can't just `rake routes`.
all_routes = Rails.application.routes.routes
require 'action_dispatch/routing/inspector'
inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
puts inspector.format(ActionDispatch::Routing::ConsoleFormatter.new)

class SomeSubtypeOfStandardError < StandardError
end

def xtest(*args, &block); end

