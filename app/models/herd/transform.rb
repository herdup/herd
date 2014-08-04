#require_dependency 'herd/transforms/'

module Herd
  class Transform < ActiveRecord::Base
    has_many :assets, dependent: :destroy

    serialize :options, HashWithIndifferentAccess
    validates_uniqueness_of :options, scope: :type

    before_validation -> {
      self.options = YAML::load(options).with_indifferent_access if options.kind_of? String
    }

    def self.options_from_string(string)
      yaml = string.split('|').map(&:strip).join("\n")
      hash = YAML::load(yaml).with_indifferent_access
    end

    def self.where_t(params)
      params[:options] = options_from_string(params[:options]).to_yaml
      params.delete :type if params[:type].nil?
      where(params)
    end

    def self.find_or_create_with_options_string(string)
      params = {options:string}
      where_t(params).first_or_create
    end


    def perform
      raise 'subclass this'
    end

  end

  class FfmpegTransform < Transform
    def self.resize_string_from(o_width,o_height,string)
      t_width, t_height = string.match(/(\d*)x(\d*)/).captures
      t_width = o_width.to_f * (t_height.to_f/o_height.to_f) unless t_width.present?
      t_height = o_height.to_f * (t_width.to_f/o_width.to_f) unless t_height.present?

      "#{t_width.to_i}x#{t_height.to_i}"
    end
    def perform(asset)
      options = self.options.symbolize_keys
      options[:resolution] = self.class.resize_string_from(asset.width,asset.height,options.delete(:resize)) if options[:resize]
      out = asset.unique_tmppath(options.delete(:format))
      asset.ffmpeg.transcode(out, options) { |progress| puts progress }
      out
    end
  end

  class SwirlGif < Transform
    def perform(asset)
      iterate = self.options.extract!(:step,:start,:end)
      transforms = (iterate[:start]..iterate[:end]).to_a.map do |ix|
        "swirl: -#{ix*iterate[:step]}"
      end

      # dont need to use child assets here necessarily
      children = transforms.each_with_index.map do |t,ix|
        asset.t(t, position:ix)
      end
      tmp_dir = Dir::Tmpname.tmpdir
      out_dir = File.join(tmp_dir,asset.file_name_wo_ext)
      FileUtils.rm_rf(out_dir)
      FileUtils.mkdir_p(out_dir)
      children.each_with_index do |a, ix|
        out_path = File.join(out_dir,"#{a.file_name_wo_ext}_#{ix}.#{a.file_ext}")
        FileUtils.cp(a.file_path, out_path)
      end
      children.reverse.drop(1).each_with_index do |a, ix|
        out_path = File.join(out_dir,"#{a.file_name_wo_ext}_#{children.count+ix}.#{a.file_ext}")
        FileUtils.cp(a.file_path, out_path)
      end
      gif_path = "#{out_dir}/#{asset.file_name_wo_ext}.gif"
      `convert -delay 1 #{out_dir}/*.jpg #{gif_path}`

      # FileUtils.rm_rf(out_dir)
      gif_path
    end
  end

  class MiniMagick < Transform
    def perform(asset)
      image = asset.mini_magick

      order = %w{resize background gravity extent}
      opts = options.keys.sort_by{ |el| order.index(el).to_i }.inject({}){|h,k|h[k]=options[k];h}

      image.combine_options do |c|
        opts.each do |k,v|
          case k
          when 'crop'
            x_regex = /\+(.*?)\+/
            y_regex = /\+([0-9]*?)$/
            x_crop_offset = v[x_regex, 1].to_i / 100.0 * asset.width
            y_crop_offset = v[y_regex, 1].to_i / 100.0 * asset.height
            image.send k, v.sub(x_regex, "+#{x_crop_offset.to_i}+").sub(y_regex, "+#{y_crop_offset.to_i}")
          else
            c.send k,v
          end
        end
      end
      out = asset.unique_tmppath(options[:format])
      image.write out
      out
    end
  end

end
