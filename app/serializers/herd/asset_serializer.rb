module Herd
  class AssetSerializer < ActiveModel::Serializer
    attributes :id
    attributes :created_at, :file_name, :file_size, :content_type, :type
    attributes :width, :height
    attributes :url
    attributes :position


    has_many :child_assets
    has_one :parent_asset

    has_one :transform, embed_in_root: true, serializer: TransformSerializer
    has_many :child_transforms

    def url
      object.file_url
    end
  end
end
