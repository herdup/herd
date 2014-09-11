module Herd
  class Page < ActiveRecord::Base
    include Assetable

    assetable_slug :path
    
  end
end
