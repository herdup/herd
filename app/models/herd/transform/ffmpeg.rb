require 'streamio-ffmpeg'

module Herd
  class Transform::Ffmpeg < Transform

    def parse_ffmpeg_options(options)
      if string = options.delete(:resize)
        t_width, t_height = string.match(/(\d*)x(\d*)/).captures

        if t_width.empty?
          t_width = "trunc(oh*a/2)*2" 
        else
          t_width = (t_height.to_i/2).round(0) * 2
        end

        if t_height.empty?
          t_height = "trunc(ow/a/2)*2" 
        else
          t_height = (t_height.to_i/2).round(0) * 2
        end

        options[:custom] ||= ''
        options[:custom] += " -vf scale='#{t_width}:#{t_height}'"
      end
      options
    end

    def perform(asset)
      parsed_options = parse_ffmpeg_options(clean_options)
      out = asset.unique_tmppath parsed_options.delete(:format)
      asset.ffmpeg.transcode(out, parsed_options) #{ |progress| yield progress if block_given? }
      out
    end
  end
end
