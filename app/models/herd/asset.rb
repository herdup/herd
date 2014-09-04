require_dependency "herd/transform"
module Herd
  class Asset < ActiveRecord::Base
    include Fileable

    attr_accessor :file
    file_field :file_name

    attr_accessor :jid
    attr_accessor :generate_sync

    scope :master, -> {where(parent_asset_id: nil)}
    scope :child, -> {where.not(parent_asset_id: nil)}

    belongs_to :assetable, polymorphic: true

    belongs_to :transform
    has_many :child_transforms, through: :child_assets, source: :transform

    belongs_to :parent_asset, class_name: 'Asset'
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
      self.assetable ||= parent_asset.try :assetable

      if file.present? # reupload
        cleanup_file if file_name.present?
        prepare_file
      end
    }

    after_save -> {
      save_file if @file.present?
    }
    after_create -> {
      generate if child? and transform.present? and !@file.present?
    }

    after_destroy :cleanup_file

    delegate :width, to: :meta_struct
    delegate :height, to: :meta_struct

    serialize :meta, Hash
    def meta_struct
      OpenStruct.new meta
    end

    def generate(async=nil)
      async ||= transform.async

      if async
        self.jid = TransformWorker.perform_async(id, transform.options)
      else
        generate!
      end
    end

    def generate!
      TransformWorker.new.perform(id, transform.options)
      reload
    end

    def child_with_transform(transform)
      # first_or_create will generate a child_asset who's parent_asset is inaccessible
      # because it's tainted with the transform_id: transform.id scope for some reason
      hash = {parent_asset:self, transform:transform}
      child = Asset.where(hash).take || Asset.create(hash)

      child.class.to_s == child.type ? child : child.becomes(type.constantize)
    end


    def t(transform_string, name=nil, async=nil)
      return unless id
      transform = computed_class.default_transform.find_or_create_with_options_string transform_string, name, assetable_type
      transform.async = async
      child_with_transform transform
    end

    def n(name, transform_string=nil, async=nil)
      return unless id
      return t transform_string, name, async
    end

    def prepare_file
      case @file
      when String
        if File.file? file
          self.file_name = File.basename(@file)
          self.file = File.open(@file)
        else
          self.file_name = File.basename URI.parse(@file).path

          # testme
          self.file = open @file,
            :content_length_proc => lambda {|t|
              if t and 0 < t and !@pbar
                @pbar = ProgressBar.new self.file_name, t
                @pbar.file_transfer_mode
              end
            },
            :progress_proc => lambda {|s|
              @pbar.set s if @pbar and s <= @pbar.total
            }
        end

      when Pathname
        # test me
        raise "no file found #{self.file}" unless @file.exist?
        self.file_name = @file.basename.to_s
        self.file = @file.open
      when ActionDispatch::Http::UploadedFile
        self.file_name = @file.original_filename
        self.content_type = @file.content_type.to_s
      when File
        self.file_name = File.basename(@file.path)
      end

      raise "no file, possibly bad url #{@file}" unless @file.try(:size)

      # test me
      self.file_size = @file.size
      # tested png
      self.content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(@file.path).split(';').first.to_s
      # tested image / video

      # should class itself try and figure this out?
      mime_parts = content_type.split('/')
      case mime_parts.first
      when 'image'
        self.type = 'Herd::Image'
      when 'video'
        self.type = 'Herd::Video'
      end


      if master? # tested
        o_file_name_wo_ext = file_name_wo_ext
        # self.file_name = "#{o_file_name_wo_ext}.#{file_ext}"

        ix = 0
        while self.class.unscoped.master.exists? file_name: self.file_name do
          ix += 1
          self.file_name = "#{o_file_name_wo_ext}-#{ix}.#{file_ext}"
        end
      end
    end

    def save_file
      File.open(file_path, "wb") { |f| f.write(file.read) }
      @file = nil
      sub = becomes(type.constantize)

      # ugly callback -- should ideally be automatically chained
      # the problem is due to the type change that happened above
      sub.did_identify_type
      sub.save if sub.changed?
    end

    def cleanup_file
      FileUtils.rm_f file_path
      if Dir["#{base_path}/*"].empty?
        FileUtils.rm_rf base_path
      end
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
