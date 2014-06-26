module Herd
  class AssetSerializer < ActiveModel::Serializer
    attributes :id
    attributes :created_at, :file_name
  end
end
