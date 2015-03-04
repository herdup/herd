module Herd
  module Sync
    class S3Import < Base
      attr_accessor :bucket

      def self.import(bucket, prefix=nil)
        new(bucket).import_s3 prefix
      end

      def initialize(bucket)
        @bucket = bucket
        accept_extensions
      end

      def import_s3(prefix=nil, s3_key=ENV['AWS_ACCESS_KEY_ID'], s3_secret=ENV['AWS_SECRET_ACCESS_KEY'])
        assets = []
        # you can update the timeouts (with seconds)
        AWS.config(:http_open_timeout => 25, :http_read_timeout => 120)
        s3 = AWS::S3.new

        objects = s3.buckets[bucket].objects
        objects = objects.with_prefix(prefix) if prefix

        objects.each do |o|
          remote_path = o.key

          next if remote_path =~ /\.DS_Store|__MACOSX|(^|\/)\._/
          next unless accept_extensions.include? File.extname(remote_path).downcase

          parts = remote_path.split '/'

          begin
           parts.first.classify.constantize
          rescue NameError
           parts.shift
          end

          asset_file = parts.pop
          assetable_slug = parts.pop

          assetable_path = Rails.root.join 'tmp', 'import', *parts, assetable_slug
          asset_path = o.url_for(:read).to_s

          begin
           klass = class_from_path parts.join '/'
          rescue Exception => e
          end

          next unless klass

          if assetable_slug == '_missing'
            if klass.missing.nil?
              klass.missing_asset = Asset.create file: asset_path
            else
              klass.missing.update file: asset_path
            end
            assets << klass.missing
            next
          else
            begin
              object = klass.friendly.find assetable_slug
            rescue Exception => e
              object = klass.find_by( klass.assetable_slug_column => assetable_slug)

              unless object
                puts "no item found #{assetable_slug} #{e} #{parts}"
                next
              end
            end
          end

          if found = object.assets.master.find_by("file_name like ?","%#{File.basename(remote_path,'.*')}%")
            if o.content_length == found.file_size
              #puts "linked this file is #{asset_path} \n exist: #{found} and same size: #{found.file_size}"
            else
              puts "updaing file with #{asset_path}"
              found.update file: asset_path
              assets << found
            end
          else
            assets << object.assets.create(file: asset_path.to_s)
          end
        end
        # ap assets
      end
    end
  end
end
