module Herd
  class AssetSerializer < ActiveModel::Serializer
    attributes :id,
     :created_at, :updated_at, 
     :file_name, 
     :file_size, 
     :content_type, 
     :type, 
     :asset_class,
     :width, :height,
     :url,
     :position,
     :metadata,
     :assetable_type, :assetable_id

    has_many :child_assets, embed: :ids, include: true, serializer: AssetSerializer, root: :assets
    has_one :parent_asset, embed: :ids, include: false
    has_one :transform,  embed: :ids, include: true, serializer: TransformSerializer

    attributes :transform_name

    def asset_class
      object.class.name.demodulize.downcase
    end

    def transform_name
      object.try(:transform).try(:name)
    end

    def url
      object.file_url
    end

    def metadata
      object.meta
    end

  end
end
