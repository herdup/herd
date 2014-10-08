module Herd
  module AssetSerializable
    extend ActiveSupport::Concern
    
    cache_me

    included do
      has_many :assets, serializer: Herd::AssetSerializer, include: true
    end
    def assetable_object
      object
    end
    def assets
      assetable_object.assets_missing
    end
  end
end
