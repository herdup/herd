module Herd
  class Transform::Ffmpeg < Transform

    def parse_ffmpeg_options(options)
      if string = options.delete(:resize)
        t_width, t_height = string.match(/(\d*)x(\d*)/).captures

        t_width = "trunc(oh*a/2)*2" if t_width.empty?


        t_height = "trunc(ow/a/2)*2" if t_height.empty?

        options[:custom] ||= ''
        options[:custom] += " -vf scale='#{t_width}:#{t_height}'"
      end
      options
    end

    def perform(asset,options)
      parsed_options = parse_ffmpeg_options(options)

      out = asset.unique_tmppath(nil, parsed_options.delete(:format))

      asset.ffmpeg.transcode(out, parsed_options) #{ |progress| yield progress if block_given? }

      out
    end
  end
end
