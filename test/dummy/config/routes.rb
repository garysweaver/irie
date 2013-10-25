Dummy::Application.routes.draw do
  resources :barfoos
  resources :foobars

  namespace :example do
    namespace :company do
      #scope '/magic' do
        resources :foobars
      #end
      resources :special_barfoos
    end
  end
end
