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

module Herd
  class Engine < ::Rails::Engine

    isolate_namespace Herd

    config.generators do |g|
      g.test_framework :rspec
      g.template_engine :haml
    end

    ActiveModel::Serializer.setup do |config|
      config.embed = :ids
    end

    initializer 'activeservice.autoload', :before => :set_autoload_paths do |app|
      app.config.eager_load_paths << "#{config.root}/app/workers"
      app.config.eager_load_paths << "#{config.root}/app/models/transforms"
    end
    # config.eager_load_paths << "#{config.root}/app/workers"
  end
end

# Wrap empty serializer has_one association in
# an empty array BOOYA fix yo bugs AMS
# https://github.com/rails-api/active_model_serializers/commit/8ca4d4fcd60aee96c4000ce98a50c37c07bc8a40
module ActiveModel
  DefaultSerializer.class_eval do
    def initialize(object, options={})
      @object = object
      @wrap_in_array = options[:_wrap_in_array]
    end

    def as_json(options={})
      return [] if @object.nil? && @wrap_in_array
      hash = @object.as_json
      @wrap_in_array ? [hash] : hash
    end
  end

  Serializer.class_eval do
    def serializable_object(options={})
      return @wrap_in_array ? [] : nil if @object.nil?
      hash = attributes
      hash.merge! associations
      @wrap_in_array ? [hash] : hash
    end
  end
end
