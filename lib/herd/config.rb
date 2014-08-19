Pathname.class_eval do
  def to_str
    to_s
  end
end

module Herd
  class Config

    class << self

      def load_transforms(path)
        path = Pathname.new(path) if path.is_a? String
        return unless path.exist?

        config = YAML::load path.read
        return unless config

        hash = config['transforms']
        return unless ActiveRecord::Base.connection.tables.include? Herd::Transform.table_name

        transforms = hash.map do |h|
          deserialize h
        end
      end

      def save_transforms(path)
        path = Pathname.new(path) if path.is_a? String

        transforms = Herd::Transform.all

        hash = transforms.map do |t|
          serialize t
        end

        container = {'transforms'=> hash}
        path.write container.to_yaml

        container
      end

      def serialize(transform)
        hash = transform.attributes
        hash.delete 'created_at'
        hash.delete 'updated_at'
        hash.delete 'id'
        hash['options'] = hash['options'].to_h
        hash
      end
      
      def deserialize(h)
        options = h.delete 'options'
        transform = Transform.where(h).first_or_create

        if transform.options.to_h != options
          transform.options = options
          transform.save!
        end

        transform
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
          TransformImportWorker.perform_async(config_path)
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
