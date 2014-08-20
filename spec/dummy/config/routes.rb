Rails.application.routes.draw do
  mount Herd::Engine => "/"

  resources :posts
  root to: 'posts#index'

end
