module Herd
  ASSETABLE_MODELS=[]
  module Assetable
    extend ActiveSupport::Concern

    included do
      has_many :assets, as: :assetable, class_name: 'Herd::Asset'
      ASSETABLE_MODELS.push(self)
    end

    module ClassMethods

    end
  end
end
