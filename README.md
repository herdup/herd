# Herd
[![Build Status](https://travis-ci.org/herdupio/herd.svg)](https://travis-ci.org/herdupio/herd)

Herds of Assets for your Rails 4 Apps.

### Installation

Just add Herd to your Gemfile:

```ruby
gem 'herd', github: 'herdup/herd', branch: 'master'
```

And then bundle it up and run a migration:

```ruby
bundle install
bundle exec rake db:migrate
```

And you're good to go!  You can now add Herd to your Models.

```ruby
class Post < ActiveRecord::Base
  include Herd::Assetable
end
```

### Using the Uploader
We're in the process of building a standard uploader component in React.  Coming soon!

### Versioning

When this library is released, it will follow the [Semantic Versioning](http://semver.org/) spec.

### Testing
Run tests with Rspec!

```ruby
bundle exec rspec
```

### Contributing

If you'd like to contribute a feature or bugfix: Thanks! To make sure your
fix/feature has a high chance of being included, please read the following
guidelines:

1. Send us a [pull request](https://github.com/herdupio/herd/compare/).
2. Please write (or edit) tests for your code!  We can't merge anything without tests. If you have questions
   about writing tests for Herd, please open a
   [GitHub issue](https://github.com/herdupio/herd/issues/new).