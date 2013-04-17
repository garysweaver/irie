class MyPostPermitter < ApplicationPermitter
  permit :name, :title, :content
end
