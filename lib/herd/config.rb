Pathname.class_eval do
  def to_str
    to_s
  end
end

module Herd
  class Config

    class << self

      def save_transforms(path, nested=true)
        path = Pathname.new(path) if path.is_a? String

        transforms  = serialize_array Herd::Transform.where.not(assetable_type: nil), nested
        defaults    = serialize_array Herd::Transform.where(assetable_type: nil), nested

        container = {
          'transforms'  => transforms,
          'defaults'    => defaults
        }

        File.open(path,'w') do |file|
          file.write container.to_yaml
        end

        container
      end

      def serialize_array(transforms, nested=true)
        list = transforms.map do |t|
          serialize t
        end

        list = list.inject({}) do |h, hh|
          h.deep_merge nest hh
        end if nested

        list
      end

      def serialize(transform, nested=nil)
        hash = transform.attributes
        hash.delete 'created_at'
        hash.delete 'updated_at'
        hash.delete 'id'

        unless hash['options'].empty?
          opts = hash.delete 'options'
          hash['options'] = opts.to_h
        else
          hash['options'] = nil
        end

        hash = nest hash if nested
        hash
      end

      def nest(h)
        out = { "#{h.delete('type').gsub('Herd::Transform::','')}" => h }

        key = h.delete('name')
        out = { "#{key}" => out } if key and key != 'default'

        key = h.delete('assetable_type')
        out = { "#{key}" => out } if key

        out
      end

      def load_transforms(path, async=nil)
        path = Pathname.new(path) if path.is_a? String
        return unless path.exist?

        config = YAML::load path.read
        return unless config
        return unless ActiveRecord::Base.connection.tables.include? Herd::Transform.table_name

        defaults = config['defaults'].map do |k,h|
          klass = k.constantize rescue "Herd::Transform::#{k}".constantize
          klass.defaults = h['options']
          klass.defaults
        end if config['defaults']

        transforms = deserialize_array(config['transforms']).map do |t|
          t.async = async
          t.save! if t.options_changed?
          t
        end
        transforms
      end

      def deserialize_array(hash_or_array)
        hash_or_array.map do |k,h|
          if h # nested hash not flat
            h.map do |name,a|
              a.map do |t,hh|
                n = { "#{k}" => { "#{name}" => { "#{t}" => hh } } }
                deserialize n
              end
            end
          else
            deserialize k
          end
        end.flatten
      end

      def deserialize(h)
        h = flatten h if h.values.count == 1

        options = h.delete 'options'
        transform = Herd::Transform.where(h).first_or_create

        transform.options = options if transform.options.to_h != options and !options.nil?

        transform
      end

      def flatten(h)
        hash = h.values.first.values.first.values.first
        hash['assetable_type'] = h.keys.first
        hash['name'] = h.values.first.keys.first
        hash['type'] = h.values.first.values.first.keys.first
        hash['type'] = hash['type'].constantize.to_s rescue "Herd::Transform::#{hash['type']}"
        hash
      end

    end

    attr_accessor :config_path

    def initialize(yml=nil)
      @config_path = yml || Rails.root.join('config/herd.yml')
      write
    end

    def write
      self.class.save_transforms config_path
    end

    def watch
      begin
        @fsevent = FSEvent.new

        # Watch the above directories
        @fsevent.watch(config_path, file_events: true) do |dirs|
          if ENV['HERD_LIVE_ASSETS'] == '1'
            TransformImportWorker.perform_async config_path
          else
            TransformImportWorker.perform config_path
          end
        end

        @fsevent.run
      rescue IOError
        # When the client disconnects, we'll get an IOError on write
      ensure
        # sse.close
        puts "watch thred closed"
      end
    end

  end
end
