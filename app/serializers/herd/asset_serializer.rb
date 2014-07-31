module Herd
  class AssetSerializer < ActiveModel::Serializer
    attributes :id
    attributes :created_at, :file_name, :file_size, :content_type, :type
    attributes :width, :height
    attributes :url
    attributes :position
    attributes :metadata

    def metadata
      object.meta
    end

    has_many :child_assets,  embed: :ids, serializer: AssetSerializer
    has_one :parent_asset,  embed: :ids, serializer: AssetSerializer

    has_one :transform,  embed: :ids, include: true, serializer: TransformSerializer

    def url
      object.file_url
    end
  end
end
