require 'haml-rails'
require 'ember-rails'
require 'ember_script-rails'
require 'emblem/rails'
require 'jquery-rails'
require 'jquery-ui-rails'

require 'active_model_serializers'
require 'filemagic'
require 'mini_magick'
require 'exifr'
require 'sidekiq'
require 'streamio-ffmpeg'
require 'progressbar'
require 'open-uri'
require 'zip'
require 'sidekiq'
require 'sidekiq-status'
require 'rb-fsevent'
require 'aws-sdk-v1'
require 'typhoeus'

module Herd
  class Engine < ::Rails::Engine
    isolate_namespace Herd

    config.generators do |g|
      g.test_framework :rspec
      g.template_engine :haml
    end

    initializer 'configure_minimagick' do |app|
      MiniMagick.configure do |config|
        config.cli = :graphicsmagick
        config.timeout = 5
      end
    end
    
    initializer "add herd to precompile", :group => :all do |app|
      app.config.assets.precompile += %w(
        application.css
        application.js
        core.js
        namespace.js
      )
    end

    initializer 'activeservice.autoload', :before => :set_autoload_paths do |app|
      app.config.autoload_paths << "#{config.root}/app/workers"
      app.config.autoload_paths << "#{config.root}/app/serializers/concerns"
      app.config.autoload_paths << "#{config.root}/lib"
    end

    initializer :setup_sidekiq_middlewares do |app|
      Sidekiq.configure_client do |config|
        config.redis = { namespace: Rails.application.class.parent_name }
        config.client_middleware do |chain|
          chain.add Sidekiq::Status::ClientMiddleware
        end
      end

      Sidekiq.configure_server do |config|
        config.redis = { namespace: Rails.application.class.parent_name }
        config.server_middleware do |chain|
          chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
        end
        config.client_middleware do |chain|
          chain.add Sidekiq::Status::ClientMiddleware
        end
      end
    end

  end
end
