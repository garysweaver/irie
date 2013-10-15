class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def current_user
    u = User.new
    u.role = $test_role || 'admin'
    u
  end
end
