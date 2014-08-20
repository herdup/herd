require 'sidekiq/web'
require 'sidekiq-status/web'

Herd::Engine.routes.draw do
  scope :herd, as: :herd do
    mount Sidekiq::Web => '/sidekiq'

    resources :assets do
      collection do
        get :live
      end
      member do
        get '/t/:options' => 'assets#transform'
      end
    end
    resources :transforms, defaults: {format: :json}
    resources :pages

    # root to: 'home#main'
  end
end
