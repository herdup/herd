Herd::Engine.routes.draw do
  resources :assets

  root to: 'home#main'
end
