ENV["RAILS_ENV"] = "test"

$:.unshift File.dirname(__FILE__)

unless ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/gemfiles/'
    add_filter '/spec/'
    add_filter '/temp/'
  end
end

require 'dummy/config/environment'
require 'dummy/db/schema'
require 'rails/test_help'

#$:.unshift File.expand_path('../support', __FILE__)
#Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

puts "Testing Rails v#{Rails.version}"
Rails.backtrace_cleaner.remove_silencers!

require 'actionizer'
Actionizer.debug = true

# Debug routes in Appraisals, since can't just `rake routes`.
#all_routes = Rails.application.routes.routes
#require 'action_dispatch/routing/inspector'
#inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
#puts inspector.format(ActionDispatch::Routing::ConsoleFormatter.new)

def default_json_options
  {format: :json, use_route: @controller.class.name.gsub('Controller', '').underscore}
end

def json_index(options = {})
  get :index, options.reverse_merge(default_json_options)
end

def json_show(options = {})
  get :show, options.reverse_merge(default_json_options)
end

def json_new(options = {})
  get :new, options.reverse_merge(default_json_options)
end

def json_edit(options = {})
  get :edit, options.reverse_merge(default_json_options)
end

def json_create(options = {})
  post :create, options.reverse_merge(default_json_options)
end

def json_update(options = {})
  put :update, options.reverse_merge(default_json_options)
end

def json_destroy(options = {})
  put :destroy, options.reverse_merge(default_json_options)
end
