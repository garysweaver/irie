# We'll just generate something random; no cookies to worry about being kept right now.
# (This is not the way Rails generates these, btw!)
# It could just as easily be '_dummy', since this is just for testing.

# Rails 3
Dummy::Application.config.secret_token = Array.new(6).fill{SecureRandom.urlsafe_base64}.join

# Rails 4
Dummy::Application.config.secret_key_base = Array.new(6).fill{SecureRandom.urlsafe_base64}.join
