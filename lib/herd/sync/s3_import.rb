module Herd
  module Sync
    class S3Import < Base
      attr_accessor :bucket
      attr_accessor :accept_extensions

      def accept_extensions
        @accept_extensions ||= %w(.jpg .gif .png .mp4 .mov .webm .m4v .tif)
      end
      def self.import(bucket, prefix=nil)
        new(bucket).import_s3 prefix
      end

      def initialize(bucket)
        @bucket = bucket
        accept_extensions
      end

      def import_s3(prefix=nil, s3_key=ENV['HERD_S3_KEY'], s3_secret=ENV['HERD_S3_SECRET'])
        assets = []

        AWS.config access_key_id:s3_key, secret_access_key: s3_secret
        s3 = AWS::S3.new

        objects = s3.buckets[bucket].objects
        objects = objects.with_prefix(bucket) if prefix

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
          asset_path = o.url_for(:read)

          # FileUtils.mkdir_p assetable_path
          # FileUtils.rm asset_path if File.exist? asset_path

          #entry.extract asset_path

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

          if found = object.assets.master.find_by(file_name: File.basename(remote_path))
            if File.stat(asset_path).size == found.file_size
              puts "linked this file is #{asset_path} \n exist: #{found} and same size: #{found.file_size}"
            else
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
