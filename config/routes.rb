Rails.application.routes.draw do
  resources :maps
  devise_for :users
  root "home#index"
  post "/" => 'home#index'
end
