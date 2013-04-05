# Be sure to restart your server when you modify this file.

if Rails::VERSION::MAJOR > 3
  Dummy::Application.config.session_store :encrypted_cookie_store, key: '_Dummy_session'
end
