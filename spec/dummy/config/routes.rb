Dummy::Application.routes.draw do
  # something is messed up in the dummy app so resourceful routing isn't working correctly
  #resource :foobars

  match "foobars/:id", :to => "foobars#show", :via => :get, :as => :foobar
  match "foobars", :to => "foobars#index", :via => :get, :as => :foobars
  match "foobars", :to => "foobars#create", :via => :post
  match "foobars/:id/edit", :to => "foobars#edit", :via => :get, :as => :edit_foobar
  match "foobars/:id", :to => "foobars#update", :via => :put
  match "foobars/new", :to => "foobars#new", :via => :get, :as => :new_foobar
  match "foobars/:id", :to => "foobars#destroy", :via => :delete
end
