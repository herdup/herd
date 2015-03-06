module Herd
  class Asset < ActiveRecord::Base
    include Fileable
    # include S3Fileable

    attr_accessor :frame_count
    attr_accessor :jid

    scope :master, -> {where(parent_asset_id: nil)}
    scope :child, -> {where.not(parent_asset_id: nil)}

    belongs_to :assetable, polymorphic: true
    belongs_to :transform
    belongs_to :parent_asset, class_name: 'Asset'

    has_many :child_transforms, through: :child_assets, source: :transform
    has_many :child_assets, class_name: 'Asset',
                            dependent: :destroy,
                            foreign_key: :parent_asset_id

    fileable_directory_fields -> (a) {
      if a.master?
        ['master']
      else
        [a.parent_asset_id,a.id].map(&:to_s)
      end
    }

    before_save -> {
      self.assetable_type ||= parent_asset.try :assetable_type
      self.assetable_id ||= parent_asset.try :assetable_id

      if file.present? # reupload
        delete_file if file_name.present?
        @file = @file.to_s if @file.kind_of? URI::HTTPS
        copy_file @file
      end
    }

    after_save -> {
      save_file if @file.present?
    }

    after_create -> {
      generate if child? and transform.present? and !@file.present?
      assetable.try :touch
    }

    after_destroy :delete_file

    delegate :width, to: :meta_struct
    delegate :height, to: :meta_struct

    serialize :meta, Hash
    def meta_struct
      OpenStruct.new meta
    end

    def generate(async=nil)
      if async || ENV['HERD_LIVE_ASSETS'] == '1' || transform.try(:async)
        self.jid = TransformWorker.perform_async id, transform.options
      else
        generate!
      end
    end

    def generate!
      TransformWorker.new.perform id, transform.options
      reload
    end

    def reset
      delete_file

      hash = {
        file_name: nil,
        file_size: nil,
        content_type: nil,
        meta: nil
      }

      update_attributes hash
    end

    def child_with_transform(transform)
      # first_or_create will generate a child_asset who's parent_asset is inaccessible
      # because it's tainted with the transform_id: transform.id scope for some reason
      hash = { parent_asset: self, transform: transform }
      child = Asset.where(hash).take || Asset.create(hash)
      child.becomes(type.constantize) rescue child
    end

    def t(transform_string, name=nil, async=nil)
      return unless id
      transform = computed_class.default_transform.find_or_create_with_options_string transform_string, name, assetable_type
      transform.async = async
      child_with_transform transform
    end

    def n(name, transform_string=nil, async=nil)
      return unless id
      trans = computed_class.default_transform.find_by(name: name) unless name.nil?
      child = child_with_transform(trans) if trans
      return child || t(transform_string, name, async)
    end

    def computed_class
      self.type.constantize
    end

    def master?
      parent_asset_id.nil?
    end
    
    def child?
      !master?
    end

  end
end