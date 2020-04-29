TestApp::Application.routes.draw do
  resources :users

  if Rails::VERSION::MAJOR >= 5
    namespace :api do
      resources :users
    end
  end
end
