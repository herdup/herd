module Herd
  module S3Fileable
    extend ActiveSupport::Concern
    include CommonFileable
    
    class Bucket
      class InvalidBasketValueException < ::Exception
      end

      attr_reader :local_tempfile

      def initialize
        @s3 = AWS::S3.new
        @bucket_name = :gravy
        @obj_cache = {}
        @local_tempfile = nil
      end

      def set_obj_cache(key)
        @obj_cache[key] = @s3.buckets[@bucket_name].objects[key]
      end
      
      def [](key)
        # no need to reach out to aws if we dont have to
        set_obj_cache key unless @obj_cache.include? key
        @obj_cache[key]
      end

      def []=(key, value)
        # interface for writing/deleting remote files
        if value.nil?
          # delete from s3
          self[key].delete
          @obj_cache.delete key
        elsif value.is_a? String
          puts "Uploading to: #{key}"
          # hopefully a URI string pointing to a real resource -- @TODO add checks
          @local_tempfile = open(value)
          content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(@local_tempfile.path).split(';').first.to_s
          write_url = self[key].url_for(:write, content_type: content_type).to_s
          request = Typhoeus::Request.new write_url, method: :put, body: @local_tempfile.read, headers: { 'content-type' => content_type }
          request.run
          set_obj_cache key
          binding.pry
        else
          raise InvalidBucketValueException
        end
      end
    end

    def bucket
      # singleton so when we call .becomes in asset, we keep this reference around
      @@bucket ||= Bucket.new
    end

    def s3_path
      @s3_path ||= [Apartment::Tenant.current, Rails.env, sanitized_classname, fileable_directory_fields.join("/"), self.file_name].join("/")
    end

    def file_path
      bucket.local_tempfile.path
    end

    def file_url
    end
    
    def copy_file(remote_path)
      self.file_name  = file_name_from_url remote_path
      # write file to bucket
      bucket[s3_path] = remote_path
      binding.pry
      content_url = URI @file
      content_url.query = nil
      self.meta[:content_url] = content_url.to_s
      self.file_size = bucket.local_tempfile.size
      self.content_type = bucket[s3_path].content_type
      set_asset_type
    end

    def save_file
      become_asset_type
    end

    def delete_file
      bucket[s3_path] = nil
    end
  end
end
