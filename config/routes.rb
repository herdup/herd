require 'sidekiq/web'
require 'sidekiq-status/web'

Herd::Engine.routes.draw do
  mount Sidekiq::Web => '/herd/sidekiq'

  scope :herd do
    resources :assets, as: :media do
      collection do
        get :live
      end
      member do
        get '/t/:options' => 'assets#transform'
      end
    end
    resources :transforms, defaults: {format: :json}
    resources :pages

    root to: 'home#main'
  end
end
