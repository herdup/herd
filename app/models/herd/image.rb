module Herd
  class Image < Asset

    def self.default_transform
      Transform::Magick
    end

    def exif
      case file_ext
      when *%w(jpg jpeg)
        EXIFR::JPEG.new(file_path) rescue nil
      end
    end

    def mini_magick(modify_orig=false)
      modify_orig ? MiniMagick::Image.new(file_path) : MiniMagick::Image.open(file_path)
    end

    def rmagick
      Magick::Image.read(file_path).first
    end

    def did_identify_type
      load_meta
      auto_orient # for camera pictures that were taken at weird angles
    end

    def load_meta
      image = mini_magick(true)
      meta[:height] = image[:height]
      meta[:width] = image[:width]

      if exif.present?
        meta[:make] = exif.make
        meta[:model] = exif.model
        meta[:gps] = exif.gps.try(:to_h)
      end
    end

    def auto_orient
      image = mini_magick(true)
      image.auto_orient
    end

  end
end
