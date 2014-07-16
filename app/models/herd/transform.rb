module Herd
  class Transform < ActiveRecord::Base
    has_many :assets, dependent: :destroy

    serialize :options, HashWithIndifferentAccess
    validates_uniqueness_of :options, scope: :type

    before_validation -> {
      self.options = YAML::load(options) if options.kind_of? String
      # self.options = options.keys.sort.inject({}) { |hash,k| hash[k] = options[k]; hash }
      self.options = options.with_indifferent_access
    }

    def self.options_from_string(string)
      yaml = string.split('|').map(&:strip).join("\n")
      hash = YAML::load(yaml)
      # hash.keys.sort.inject({}) { |h,k| h[k] = hash[k]; h }.with_indifferent_access
    end

    def self.find_by_options(hash)
      match = YAML::dump(hash.with_indifferent_access)
      where(options:match).take
    end

    def self.find_or_create_with_options_string(string)
      find_by_options(options_from_string(string)) || create(type:'Herd::MiniMagick', options: YAML::dump(options_from_string(string)))
    end


    def perform
      raise 'subclass this'
    end

  end

  class Zip < Transform
    def perform(assets)

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
