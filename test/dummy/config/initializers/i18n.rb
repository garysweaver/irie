# avoid deprecation message with i18n 0.6.9
begin
  I18n.enforce_available_locales = false
rescue
end
