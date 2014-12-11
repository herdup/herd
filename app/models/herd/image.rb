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

    def did_identify_type
      self.meta.merge! load_meta
      auto_orient # for camera/phone pictures that were taken at weird angles
    end

    def load_meta
      hash = {}
      image = mini_magick(true)

      hash[:height] = image.height
      hash[:width]  = image.width

      if exif.present?
        hash[:make] = exif.make
        hash[:model] = exif.model
        hash[:gps] = exif.gps.try(:to_h)
      end
      hash.delete_if {|k,v|v.nil?} # make sense er na? cleaner db
      hash
    end

    def auto_orient
      image = mini_magick(true)
      image.auto_orient
    end

  end
end
