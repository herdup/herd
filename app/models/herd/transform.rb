#require_dependency 'herd/transforms/'

module Herd
  class Transform < ActiveRecord::Base
    has_many :assets, dependent: :destroy

    serialize :options, HashWithIndifferentAccess
    validates_uniqueness_of :options, scope: :type

    before_validation -> {
      # if attributes['options'].kind_of?(String)
      #   attributes['options'] = YAML::load(attributes['options']).with_indifferent_access
      # end
      #self.options = YAML::load(self.options).with_indifferent_access unless self.options
      self.options = YAML::load(options).with_indifferent_access if options.kind_of? String
    }

    def self.options_from_string(string)
      yaml = string.split('|').map(&:strip).join("\n")
      hash = YAML::load(yaml)
      # hash.keys.sort.inject({}) { |h,k| h[k] = hash[k]; h }.with_indifferent_access
    end

    def self.where_t(params)
      params[:options] = YAML::load(params[:options]).with_indifferent_access.to_yaml
      where(params)
    end

    def self.find_by_options(hash)
      match = YAML::dump(hash.with_indifferent_access)
      where(options:match).take
    end

    def self.find_or_create_with_options_string(string)
      hash = options_from_string(string)
      klass = hash.delete('type').constantize if hash['type']
      klass ||= MiniMagick
      klass.find_by_options(hash) || klass.create(options: hash.to_yaml)
    end


    def perform
      raise 'subclass this'
    end

  end

  class Zip < Transform
    def perform(assets)

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
