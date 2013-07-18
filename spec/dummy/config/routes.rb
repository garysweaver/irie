Dummy::Application.routes.draw do
  resources :barfoos, :special_barfoos do
    get 'some_action', :on => :collection
  end

  resources :foobars
  resources :posts
  resources :my_posts
end
