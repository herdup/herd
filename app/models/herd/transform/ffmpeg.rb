module Herd
  class Transform::Ffmpeg < Transform
    def self.resize_string_from(o_width,o_height,string)
      t_width, t_height = string.match(/(\d*)x(\d*)/).captures
      t_width = o_width.to_f * (t_height.to_f/o_height.to_f) unless t_width.present?
      t_height = o_height.to_f * (t_width.to_f/o_width.to_f) unless t_height.present?

      t_height += 1 unless t_height.to_i.even?
      t_width += 1 unless t_width.to_i.even?

      "#{t_width.to_i}x#{t_height.to_i}"
    end
    def perform(asset,options)
      options = options.symbolize_keys
      options[:resolution] = self.class.resize_string_from(asset.width,asset.height,options.delete(:resize)) if options[:resize]
      out = asset.unique_tmppath(options.delete(:format))
      asset.ffmpeg.transcode(out, options) { |progress| yield progress if block_given? }
      out
    end
  end
end
