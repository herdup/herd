module Herd
  module Sync
    class S3Import < Base

      def initialize(bucket, prefix='', s3_key=ENV['AWS_ACCESS_KEY_ID'], s3_secret=ENV['AWS_SECRET_ACCESS_KEY'])
        @bucket = bucket
        @prefix = prefix
        AWS.config access_key_id: s3_key, secret_access_key: s3_secret, http_open_timeout: 30, http_read_timeout: 120
      end

      def s3
        @s3 ||= AWS::S3.new
      end

      def import_s3(namespace='')
        assets = []

        objects = s3.buckets[@bucket].objects
        objects = objects.with_prefix(@prefix) unless @prefix.blank?

        objects.each do |o|
          remote_path = o.key

          next if remote_path =~ /\.DS_Store|__MACOSX|(^|\/)\._/
          next unless accept_extensions.include? File.extname(remote_path).downcase

          parts = remote_path.split('/').drop 1 # get rid of client namespace

          asset_file = parts.pop
          assetable_slug = parts.pop
          assetable_path = Rails.root.join 'tmp', 'import', *parts, assetable_slug
          asset_path = o.url_for :read

          klass = class_from_path parts.unshift(namespace).join '/' rescue nil

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
              puts "linked this file is #{asset_path} \n exist: #{found} and same size: #{found.file_size}"
            else
              puts "updating file with #{asset_path.to_s}"
              found.update file: asset_path
              assets << found
            end
          else
            assets << object.assets.create(file: asset_path)
          end
        end
      end
    end
  end
end
