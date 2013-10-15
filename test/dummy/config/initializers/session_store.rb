begin; Dummy::Application.config.session_store :encrypted_cookie_store, key: '_Dummy_session'; rescue; end
begin; Dummy::Application.config.session_store :cookie_store; rescue; end
