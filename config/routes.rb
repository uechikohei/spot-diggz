Rails.application.routes.draw do
  resources :maps
  devise_for :users
  root "home#index"
  get 'users/:id', to: 'users#show'
  get 'users', to: 'users#index'
  post "/" => 'home#index'
end
