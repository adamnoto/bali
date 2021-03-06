# To check available routes:
#
# Rails.application.routes.routes.each do |route|
#   puts route.path.spec.to_s
# end; nil

TestApp::Application.routes.draw do
  resources :users, only: [:index, :show] do
    collection do
      get :index_no_current_user
    end
  end

  resources :transactions, only: [:index]

  if Rails::VERSION::MAJOR >= 5
    namespace :api do
      resources :users, only: [:show]
      resources :transactions, only: [:index]
    end
  end
end
