module Herd
  class AssetSerializer < ActiveModel::Serializer
    embed :ids
    attributes :id
    attributes :created_at, :file_name, :file_size, :content_type, :type
    attributes :width, :height
    attributes :url

    has_many :child_assets
    has_one :parent_asset

    def url
      object.file_url
    end
  end
end
