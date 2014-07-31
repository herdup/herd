require_dependency "herd/transform"
module Herd
  class Asset < ActiveRecord::Base
    include Fileable

    attr_accessor :file
    file_field :file_name

    # validates :file_name, presence: true

    scope :master, -> {where(parent_asset_id: nil)}
    scope :child, -> {where.not(parent_asset_id: nil)}

    belongs_to :assetable, polymorphic: true

    belongs_to :transform
    has_many :child_transforms, through: :child_assets, source: :transform

    belongs_to :parent_asset, class_name: 'Asset'
    has_many :child_assets, class_name: 'Asset',
                            dependent: :destroy,
                            foreign_key: :parent_asset_id

    default_scope -> {
      order(:position)
    }

    fileable_directory_fields -> (a) {
      if a.master?
        "master"
      else
        "#{a.parent_asset_id.to_i}/#{a.id}"
      end
    }

    before_create -> {
      if parent_asset.present?
        self.file ||= transform.perform(parent_asset) if transform_id.present?
        self.assetable ||= parent_asset.assetable
      end
      prepare_file if file.present?
    }

    after_create -> {
      save_file if file.present?
    }
    after_destroy :cleanup_file

    delegate :width, to: :meta_struct
    delegate :height, to: :meta_struct

    serialize :meta, Hash
    def meta_struct
      @meta_struct ||= OpenStruct.new meta
    end

    def t(transform_string,params=nil)
      # klass ||= Herd::MiniMagick
      transform = self.class.default_transform.find_or_create_with_options_string(transform_string)

      # first_or_create will generate a child_asset who's parent_asset is inaccessible
      # because it's tainted with the transform_id: transform.id scope for some reason
      hash = {parent_asset:self, transform:transform}
      child = Asset.where(hash).first || Asset.create(hash)
      child.update params if params.present?
      child.class.to_s == child.type ? child : child.becomes(type.constantize)
    end

    def prepare_file
      case @file
      when String
        if File.file? file
          self.file_name = File.basename(@file)
          self.file = File.open(@file)
        else
          uri = URI.parse(@file)
          self.file = open(@file)
          self.file_name = File.basename(uri.path)
        end
      when ActionDispatch::Http::UploadedFile
        self.file_name = @file.original_filename
        self.content_type = @file.content_type.to_s
      end
      self.file_size = @file.size
      self.content_type ||= FileMagic.new(::FileMagic::MAGIC_MIME).file(@file.path).split(';').first.to_s
      set_asset_type

      o_file_name_wo_ext = file_name_wo_ext
      self.file_name = "#{o_file_name_wo_ext}.#{file_ext}"
      ix = 0
      while self.class.master.exists? file_name: self.file_name do
        ix += 1
        self.file_name = "#{o_file_name_wo_ext}-#{ix}.#{file_ext}"
      end
    end

    def save_file

      File.open(file_path, "wb") { |f| f.write(file.read) }
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

    def set_asset_type
      mime_parts = content_type.split('/')
      case mime_parts.first
      when 'image'
        self.type = 'Herd::Image'
      when 'video'
        self.type = 'Herd::Video'
      end
      # sub = becomes(type.constantize)

      # ugly callback -- should ideally be automatically chained
      # the problem is due to the type change that happened above
      # sub.did_identify_type
    end

    def sanitized_classname
      # use the second path chunk for now (i.e. what's after "Rcms::")
      # not ideal but cant figure out an easy way around it
      type_s = self.type
      type_s ||= self.class.to_s
      type_s.split("::").second.pluralize.downcase
    end

    def master?
      parent_asset_id.nil?
    end
  end

  class Video < Asset
    def self.default_transform
      FfmpegTransform
    end

    def ffmpeg
      FFMPEG.logger.level = Logger::ERROR
      FFMPEG::Movie.new file_path
    end

    def did_identify_type
      load_meta
    end

    def load_meta
      movie = ffmpeg
      self.meta = {
        resolution: movie.resolution,
        height: movie.height,
        width: movie.width,
        frame_rate: movie.frame_rate,
        video_codec: movie.video_codec,
        bitrate: movie.bitrate,
        duration: movie.duration
      }
    end
  end

  class Image < Asset

    def self.default_transform
      MiniMagick
    end

    def exif
      case file_ext
      when *%w(jpg jpeg)
        EXIFR::JPEG.new(file_path) rescue nil
      end
    end

    def mini_magick
      @mini_magick ||= ::MiniMagick::Image.open(file_path)
    end

    def rmagick
      @rmagick ||= Magick::Image.read(file_path).first
    end

    def did_identify_type
      load_meta
      auto_orient # for camera pictures that were taken at weird angles
    end

    def load_meta
      image = mini_magick
      meta[:height] = image[:height]
      meta[:width] = image[:width]

      if exif.present?
        meta[:make] = exif.make
        meta[:model] = exif.model
        meta[:gps] = exif.gps.try(:to_h)
      end
    end

    def auto_orient
      image = mini_magick
      image.auto_orient
      image.write file_path
    end


  end
end
