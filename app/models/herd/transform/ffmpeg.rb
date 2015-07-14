require 'streamio-ffmpeg'

module Herd
  class Transform::Ffmpeg < Transform

    def parse_ffmpeg_options(opts)
      if string = opts.delete(:resize)
        t_width, t_height = string.match(/(\d*)x(\d*)/).captures

        if t_width.empty?
          t_width = "trunc(oh*a/2)*2" 
        else
          t_width = (t_width.to_i/2).round(0) * 2
        end

        if t_height.empty?
          t_height = "trunc(ow/a/2)*2" 
        else
          t_height = (t_height.to_i/2).round(0) * 2
        end
        opts[:custom] ||= ''
        opts[:custom] += " -vf scale='#{t_width}:#{t_height}'"
      end
      opts
    end

    def perform(asset)
      parsed_options = parse_ffmpeg_options(options_with_defaults)
      ap parsed_options
      out = asset.unique_tmppath parsed_options.delete(:format)
      asset.ffmpeg.transcode(out, parsed_options) #{ |progress| yield progress if block_given? }
      out
    end
  end
end
