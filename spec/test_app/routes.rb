# To check available routes:
#
# Rails.application.routes.routes.each do |route|
#   puts route.path.spec.to_s
# end; nil

TestApp::Application.routes.draw do
  resources :users, only: [:show]

  if Rails::VERSION::MAJOR >= 5
    namespace :api do
      resources :users, only: [:show]
    end
  end
end
