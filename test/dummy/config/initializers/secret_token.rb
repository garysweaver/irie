if Rails::VERSION::MAJOR < 4
  Dummy::Application.config.secret_token = SecureRandom.urlsafe_base64 * 2
else
  Dummy::Application.config.secret_key_base = SecureRandom.urlsafe_base64 * 2
end
