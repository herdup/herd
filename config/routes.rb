Herd::Engine.routes.draw do
  scope :herd do
    resources :assets do
      member do
        get '/t/:options' => 'assets#transform'
      end
      get :empty_zip, on: :collection
    end
    resources :transforms, defaults: {format: :json}
    resources :pages

    root to: 'home#main'
  end
end
