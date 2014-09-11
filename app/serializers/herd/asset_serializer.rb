module Herd
  class AssetSerializer < ActiveModel::Serializer
    attributes :id
    attributes :created_at, :updated_at, :file_name, :file_size, :content_type, :type
    attributes :width, :height
    attributes :url
    attributes :position
    attributes :metadata
    attributes :assetable_type, :assetable_id

    has_many :child_assets,  embed: :ids
    has_one :parent_asset,  embed: :ids

    has_one :transform,  embed: :ids, include: true, serializer: TransformSerializer

    def url
      object.file_url
    end

    def metadata
      object.meta
    end
  end
end
