Rails.application.routes.draw do
  root "home#index"
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  devise_scope :user do
    post 'users/guest_sign_in', to: 'users/sessions#new_guest'
  end
  get 'users/:id', to: 'users#show'
  post "/" => 'home#index'
  resources :users
  # ブロック関数を使用
  resources :maps do
    resources :likes, only: [:create, :destroy]
  end
end
