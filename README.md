# Herd
[![Build Status](https://travis-ci.org/herdupio/herd.svg)](https://travis-ci.org/herdupio/herd)

Herds of Assets for your Rails 4 Apps.

Dependent on PostgreSQL `gem 'pg'`

### Installation

Just add Herd to your Gemfile:

```ruby
gem 'herd', github: 'herdup/herd', branch: 'master'
```

And then bundle it up and run a migration:

```ruby
bundle install
bundle exec rake herd:install:migrations
bundle exec rake db:migrate
```

And you're good to go!  You can now add Herd to your Models.

```ruby
class Post < ActiveRecord::Base
  include Herd::Assetable
end
```

Mount Herd API in your routes

```ruby
Rails.application.routes.draw do
  mount Herd::Engine, at: '/'
  ...
end
```

Mount the helpers (if you're using rails templates)

```ruby
class ApplicationController < ActionController::Base
  helper Herd::Engine.helpers
  helper Herd::Engine.routes.url_helpers
  ...
end
```

### Using the Uploader

Drop in an uploader for your assetable model (@pano is mines)


```erb
<%= assetable_uploader @pano %>

```

### Release the Herd!

Display your attached assets! a.t *transform string*, *name*

```erb
<% @pano.assets.each do |a| %>
  <%= herd_tag a.t 'resize: x420', 'edit' %>
<% end %>
```


### Enable S3

Currently S3 can be enabled using your Rails secrets.yml file. 

```yml
production:
  herd_s3_key: abc123
  herd_s3_secret: zyxlmnop123
  herd_s3_enabled: true
  herd_s3_bucket: dev-herd
```

Note: If you already have `ENV["AWS_ACCESS_KEY_ID"]` / `ENV["AWS_SECRET_ACCESS_KEY"]`, herd will use those instead.

Note: Changing this setting will break existing assets. See import/export process to move assets between s3/filesystem

### Transform Defaults



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