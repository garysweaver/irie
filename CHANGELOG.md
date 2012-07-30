# CHANGELOG

## 2.0.0

 * Instead of set_json_format, have paired down to default_as_json_includes

## 1.0.0

 * Uses a Railtie to extend ActionController::Base to provide acts_as_restful_json, which if called will include restful_json functionality in the controller
 * Uses a Railtie to extend ActiveRecord::Base so that the user can define json format via set_json_format
 * Determines format via json_format request parameter, optional referer pathname and dirpath, controller, and action, model default, or ActiveRecord to_json default
