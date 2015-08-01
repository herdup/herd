require 'streamio-ffmpeg'

module Herd
  class Video < Asset
    def self.default_transform
      Herd::Transform::Ffmpeg
    end

    def ffmpeg
      FFMPEG.logger.level = Logger::ERROR
      FFMPEG::Movie.new file_path
    end

    def did_identify_type
      self.meta.merge! load_meta
    end

    def load_meta
      movie = ffmpeg
      
      {
        resolution: movie.resolution,
        height: movie.height,
        width: movie.width,
        frame_rate: movie.frame_rate,
        video_codec: movie.video_codec,
        bitrate: movie.bitrate,
        duration: movie.duration
      }
    end
  end
end
