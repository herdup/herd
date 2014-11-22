module Herd
  class Transform::Ffmpeg < Transform
    def perform(asset,options)
      options = options.symbolize_keys

      if string = options.delete(:resize)
        t_width, t_height = string.match(/(\d*)x(\d*)/).captures
        t_width = -1 if t_width.empty?
        t_height = -1 if t_height.empty?
        #TODO: ensure integers, even?
        options[:custom] ||= ''
        options[:custom] += "-vf scale=#{t_width}:#{t_height}"
      end

      out = asset.unique_tmppath(nil, options.delete(:format).to_s)

      asset.ffmpeg.transcode(out, options) { |progress| yield progress if block_given? }
      out
    end
  end
end
