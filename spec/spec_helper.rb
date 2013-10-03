ENV['RAILS_ENV'] = 'test'

unless ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/gemfiles/'
    add_filter '/spec/'
    add_filter '/temp/'
  end
end

puts "Testing Rails v#{Rails.version}"

# add dummy to the load path. now we're also at the root of the fake rails app.
app_path = File.expand_path("../dummy",  __FILE__)
$LOAD_PATH.unshift(app_path) unless $LOAD_PATH.include?(app_path)

require 'actionizer'

# if require rails, get uninitialized constant ActionView::Template::Handlers::ERB::ENCODING_FLAG (NameError)
require 'rails/all'
require 'config/environment'
require 'db/schema'
require 'rails/test_help'

require 'rake'

# Debug routes in Appraisals, since can't just `rake routes`.
#all_routes = Rails.application.routes.routes
#require 'action_dispatch/routing/inspector'
#inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
#puts inspector.format(ActionDispatch::Routing::ConsoleFormatter.new)

require 'rspec/rails'
require 'json_spec'
require 'database_cleaner'

Rails.backtrace_cleaner.remove_silencers!

#Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  require 'rspec/expectations'
  config.include RSpec::Matchers
  config.mock_with :rspec
  config.order = :random
  config.include JsonSpec::Helpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

def json_index(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  get :index, options.reverse_merge(format: :json, use_route: resource_name)
end

def json_show(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  get :show, options.reverse_merge(format: :json, use_route: resource_name)
end

def json_new(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  get :new, options.reverse_merge(format: :json, use_route: resource_name)
end

def json_edit(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  get :edit, options.reverse_merge(format: :json, use_route: resource_name)
end

def json_create(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  post :create, options.reverse_merge(format: :json, use_route: resource_name)
end

def json_update(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  put :update, options.reverse_merge(format: :json, use_route: resource_name)
end

def json_destroy(options = {})
  resource_name = @controller.class.name.gsub('Controller', '').underscore
  put :destroy, options.reverse_merge(format: :json, use_route: resource_name)
end
