Rails.application.routes.draw do
  resources :stocks
  devise_for :users
  root "home#index"
  get "home/about"
  post "/" => 'home#index'

  # google maps javascript api 導入してみる！
  get "maps/index"
end
