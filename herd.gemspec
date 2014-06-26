$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "herd/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "herd"
  s.version     = Herd::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Herd."
  s.description = "TODO: Description of Herd."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.1"
  s.add_dependency "rspec-rails", "~> 2.14.1"
  s.add_dependency "haml-rails"
  s.add_dependency "coffee-rails"
  s.add_dependency 'ember-rails'
  s.add_dependency 'ember-source'
  s.add_dependency 'emblem-rails'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'active_model_serializers'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'quiet_assets'

end
