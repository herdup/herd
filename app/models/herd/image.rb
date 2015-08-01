require 'exifr'
require 'mini_magick'

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
    end

    def load_meta
      hash = {}
      image = mini_magick(true)

      if exif.present?
        hash[:make]   = exif.make
        hash[:model]  = exif.model
        hash[:gps]    = exif.gps.try(:to_h)
       
        # Auto Orient if Available
        image.try :auto_orient
      end

      hash[:height] = image.height
      hash[:width]  = image.width

      hash.delete_if {|k,v|v.nil?} # make sense er na? cleaner db
      hash
    end

  end
end
