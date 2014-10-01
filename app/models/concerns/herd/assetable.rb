module Herd
  ASSETABLE_MODELS=[]
  module Assetable
    extend ActiveSupport::Concern

    included do
      ASSETABLE_MODELS.push(self)

      has_many :assets, -> {order(:position)}, as: :assetable, class_name: 'Herd::Asset', dependent: :destroy
      has_many :master_assets, -> {master.order(:position)}, as: :assetable, class_name: 'Herd::Asset', dependent: :destroy

      assetable_slug
    end

    def asset
      assets.master.take || self.class.missing_assets.take || Asset.new
    end

    def transforms
      self.class.transforms
    end

    def assets_missing
      assets.empty? ? self.class.missing_assets : assets
    end

    module ClassMethods

      def transforms
        Transform.where assetable_type: to_s
      end
      def missing_assets
        Asset.where(assetable_type: to_s, assetable_id: 0)
      end
      def missing_asset=(asset)
        asset.update_column :assetable_type, to_s
        asset.update_column :assetable_id, 0
      end
      def missing
        missing_assets.take
      end
      def find_by_assetable_slug(slug)
        find_by assetable_slug_column => slug
      end
      def assetable_slug(sym=:slug)
        define_singleton_method :assetable_slug_column do
          sym
        end
        define_method :assetable_slug do
          send self.class.assetable_slug_column
        end
      end

    end
  end
end
