require 'haml-rails'
require 'jquery-rails'
require 'ember-rails'
require 'emblem/rails'
require 'active_model_serializers'

module Herd
  class Engine < ::Rails::Engine
    isolate_namespace Herd
    config.generators do |g|
      g.test_framework :rspec
      g.template_engine :haml
    end
  end
end
