class MyPostPermitter < ActionController::Permitter
  permit :name, :title, :content
end
