require 'mini_magick'

MiniMagick::Image.class_eval do
  attr_reader :tempfile
end

module Herd
  class Transform::Magick < Transform
    def perform(asset_or_id)
      asset = computed_asset asset_or_id
      image = asset.mini_magick

      order = %w{resize background gravity extent}
      opts = clean_options.keys.sort_by{ |el| order.index(el).to_i }.inject({}){|h,k|h[k]=options[k];h}

      image.combine_options do |c|
        opts.each do |k,v|
          case k
          when 'format'
            image.send k, v
          when 'crop'
            if v.match '%'
              x_regex = /\+(.*?)\+/
              y_regex = /\+([0-9]*?)$/
              x_crop_offset = v[x_regex, 1].to_i / 100.0 * asset.width
              y_crop_offset = v[y_regex, 1].to_i / 100.0 * asset.height
              image.send k, v.sub(x_regex, "+#{x_crop_offset.to_i}+").sub(y_regex, "+#{y_crop_offset.to_i}")
            else
              image.send k, v
            end
          else
            c.send k,v
          end
        end
      end
      out = asset.unique_tmppath clean_options[:format]
      puts "--about to write to #{out}"
      puts "--file at #{image.tempfile.path}"
      image.write out
      image.tempfile.close
      image.tempfile.delete
      out
    end
  end
end
