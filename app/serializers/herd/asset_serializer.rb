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


    has_many :child_assets#, embed_in_root: false
    has_one :parent_asset#, embed_in_root: false

    has_one :transform, serializer: TransformSerializer
    has_many :child_transforms#, embed_in_root: false

    def url
      object.file_url
    end
  end
end
