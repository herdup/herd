module Herd
  class Transform::Split < Transform::Ffmpeg
    def perform(asset, options)
      parsed_options = parse_ffmpeg_options(options)
      #TODO: defaults should live somwhere else?
      parsed_options[:format] ||= 'jpg'
      parsed_options[:frame_rate] = 5

      dir = Dir::Tmpname.tmpdir + "/" + asset.file_name_wo_ext
      Dir.mkdir dir unless Dir.exists? dir

      out = dir + '/%d.' + options.delete(:format)

      asset.ffmpeg.transcode(out, parsed_options, {validate:false}) #{ |progress| yield progress if block_given? }

      out
    end
  end
end
