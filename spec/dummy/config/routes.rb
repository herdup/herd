Rails.application.routes.draw do
  mount Herd::Engine => "/", as: :herd

  resources :posts
  root to: 'posts#index'

end
