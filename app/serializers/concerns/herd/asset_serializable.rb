module Herd
  module AssetSerializable
    extend ActiveSupport::Concern
    included do
      has_many :assets, serializer: Herd::AssetSerializer
      def assets
        # binding.pry
        object.assets_missing
      end
    end
  end
end
