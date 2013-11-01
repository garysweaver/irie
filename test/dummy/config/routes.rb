Dummy::Application.routes.draw do
  resources :barfoos

  namespace :example do
    namespace :alpha do
      #scope '/magic' do
      resources :foobars
      #end
      resources :special_barfoos
    end
    namespace :beta do
      resources :foobars
    end
  end
end
