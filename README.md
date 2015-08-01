# Herd
[![Build Status](https://travis-ci.org/herdupio/herd.svg)](https://travis-ci.org/herdupio/herd)

Herds of Assets for your Rails 4 Apps.

**Note:** Herd is dependent on PostgreSQL `gem 'pg'`

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

**Note:** Using Ember CLI?  Checkout the [Herd Ember](https://github.com/herdup/herd-ember) addon.

### Release the Herd!

Display your attached assets! a.t *transform string*, *name*

```erb
<% @pano.assets.each do |a| %>
  <%= herd_tag a.t 'resize: x420', 'edit' %>
<% end %>
```

### Enable S3

Herd is designed to be used with S3.  To enable S3:

#### Setup your Host Application

Currently S3 can be enabled using your Rails secrets.yml file. 

```yml
production:
  herd_s3_key: your_s3_key_here
  herd_s3_secret: your_s3_secret_key_here
  herd_s3_enabled: true
  herd_s3_bucket: myapp-production-bucket
  herd_s3_path_prefix: assets 
```

**Note**: If you already have `ENV["AWS_ACCESS_KEY_ID"]` / `ENV["AWS_SECRET_ACCESS_KEY"]`, Herd will use those instead.

**Note**: Changing this setting will break existing assets. See import/export process to move assets between s3/filesystem

#### S3 Bucket Configuration

You'll also need to setup a S3 bucket, and allow it to be accessed publicly. Add a policy such as:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::MY-BUCKET-NAME/*"
        }
    ]
}
```

If you're requesting images from the bucket via JS, you'll want to Edit the Buckets CORS configuration too:

```
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <CORSRule>
        <AllowedOrigin>http://*</AllowedOrigin>
        <AllowedOrigin>https://*</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>Authorization</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```

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
