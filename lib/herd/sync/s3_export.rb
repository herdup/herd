require 'aws-sdk-v1'

module Herd
  module Sync
    class S3Export < Base
      attr_accessor :output_assets

      def initialize(bucket, output_assets=true, s3_key=ENV['AWS_ACCESS_KEY_ID'], s3_secret=ENV['AWS_SECRET_ACCESS_KEY'])
        @bucket = bucket
        @output_assets = output_assets
        AWS.config(:http_open_timeout => 25, :http_read_timeout => 120)
        AWS.config access_key_id:s3_key, secret_access_key: s3_secret
      end

      def s3
        AWS::S3.new
      end

      def delete_s3(prefix=nil)
        s3.buckets[@bucket].clear!
      end

      def export_s3(prefix=nil)
        folder_map.each do |class_path, assetables|
          klass = class_from_path class_path
          if @output_assets and klass.missing.present?
            a = klass.missing
            asset_key = File.join prefix, class_path, '_missing', File.basename(a.file_name)
            s3.buckets[@bucket].objects[asset_key].write(file: a.file_path)
          end

          assetables.each do |slug|
            s3.buckets[@bucket].objects[File.join(prefix, class_path, slug) + '/'].write data: ''

            if @output_assets
              object = klass.find_by_assetable_slug slug
              object.assets.master.each do |a|
                asset_key = File.join prefix, class_path, slug, File.basename(a.file_name)
                s3.buckets[@bucket].objects[asset_key].write(file: a.file_path)
              end
            end
          end
        end
      end
    end
  end
end
