module Herd
  class AssetSerializer < ActiveModel::Serializer
    attributes :id
    attributes :created_at, :updated_at, :file_name, :file_size, :content_type, :type, :asset_class
    attributes :width, :height
    attributes :url
    attributes :position
    attributes :metadata
    attributes :assetable_type, :assetable_id

    has_many :child_assets,  embed: :ids, include: true, serializer: AssetSerializer
    has_one :parent_asset,  embed: :ids

    has_one :transform,  embed: :ids, include: true, serializer: TransformSerializer

    attributes :transform_name

    def include_child_assets?
      object.association(:child_assets).loaded?
    end
    def include_parent_asset?
      object.association(:parent_asset).loaded?
    end
    def include_transform?
      object.association(:transform).loaded?
    end

    def asset_class
      object.class.name.demodulize.downcase
    end

    def transform_name
      object.try(:transform).try(:name) unless object.master? 
    end

    def url
      object.file_url
    end

    def metadata
      object.meta
    end

  end
end
