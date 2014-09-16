$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "herd/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "herd"
  s.version     = Herd::VERSION
  s.authors     = ["Sebastian Bean"]
  s.email       = ["sebastian@ginlanemedia.com"]
  s.homepage    = "nah.com"
  s.summary     = "Asset mgmt for 2020"
  s.description = "TODO: Description of Herd."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "> 4"
  s.add_dependency "rspec-rails"#, "~> 2.14.1"
  s.add_dependency "haml-rails"
  s.add_dependency "coffee-rails"
  s.add_dependency 'ember-rails'
  s.add_dependency 'ember-source'
  s.add_dependency 'emblem-rails'
  s.add_dependency 'ember_script-rails'
  s.add_dependency 'jquery-rails', '~> 3.1.0'
  s.add_dependency 'jquery-ui-rails', '4.1.2'
  s.add_dependency 'active_model_serializers','0.8.1' #"~> 0.9.0.alpha1"

  s.add_dependency 'progressbar'
  s.add_dependency 'ruby-filemagic'
  s.add_dependency 'mini_magick'
  s.add_dependency 'streamio-ffmpeg'
  s.add_dependency 'exifr'
  s.add_dependency 'rubyzip'
  s.add_dependency 'sidekiq'
  s.add_dependency 'sidekiq-status'
  s.add_dependency 'sinatra'
  s.add_dependency 'rb-fsevent'
  s.add_dependency 'aws-sdk-v1'

  # s.add_development_dependency 'aws-sdk-v1'
  s.add_development_dependency "sqlite3"

end
