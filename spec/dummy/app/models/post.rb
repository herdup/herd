class Post < ActiveRecord::Base
  include Herd::Assetable

  assetable_slug :title
end
