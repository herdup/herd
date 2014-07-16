Herd::Engine.routes.draw do
  resources :assets do
    member do
      get '/t/:options' => 'assets#transform'
    end
  end
  resources :transforms, defaults: {format: :json}

  root to: 'home#main'
end
