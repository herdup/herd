module Herd
  class PageSerializer < ActiveModel::Serializer
    attributes :id
    attributes :path
    has_many :assets, embed: :ids, include: true, serializer: AssetSerializer
  end
end
