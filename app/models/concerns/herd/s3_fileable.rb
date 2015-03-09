module Herd
  module S3Fileable
    extend ActiveSupport::Concern
    include CommonFileable
    
    class Bucket
      class InvalidBucketValueException < ::Exception
      end

      AWS::S3::S3Object.class_eval do
        attr_accessor :local_tempfile

        def local_tempfile
          return @local_tempfile unless @local_tempfile.nil?
          @local_tempfile = Tempfile.open('tmp', Dir::Tmpname.tmpdir) do |file|
            file.binmode
            self.read do |chunk|
              file.write(chunk)
            end
          end
        end
      end

      def initialize
        @s3 = AWS::S3.new
        @bucket_name = Rails.application.secrets.herd_s3_bucket
        @obj_cache = {}
      end

      def set_obj_cache(key, local_tempfile=nil)
        obj = @s3.buckets[@bucket_name].objects[key]
        obj.local_tempfile = local_tempfile unless local_tempfile.nil?
        @obj_cache[key] = obj
      end
      
      def [](key)
        # no need to reach out to aws if we dont have to
        set_obj_cache key unless @obj_cache.include? key
        @obj_cache[key]
      end

      def []=(key, value_and_content_type)
        value_and_content_type = value_and_content_type.presence || []
        value, content_type = value_and_content_type.shift 2
        # interface for writing/deleting remote files
        if value.nil?
          # delete from s3
          self[key].delete
          @obj_cache.delete key
        elsif value.class.in? [File, Tempfile]
          write_url = self[key].url_for(:write, content_type: content_type).to_s
          Typhoeus::Request.new(write_url, method: :put, body: value.read, headers: { 'content-type' => content_type }).run
          puts "Uploaded to: #{key} with content type: #{content_type}"
          set_obj_cache key, value
        else
          raise InvalidBucketValueException
        end
      end
    end

    def bucket
      # singleton so when we call .becomes in asset, we keep this reference around
      @@bucket ||= Bucket.new
    end

    def base_path
      # we need the asset type before we can write to s3
      # this is different from regular fileable because here we write the file first
      @base_path ||= [Apartment::Tenant.current, Rails.env, sanitized_classname, fileable_directory_fields.join("/"), self.file_name].join("/")
    end

    def file_path
      # check if local file exists and return that otherwise download the file 
      path = bucket[base_path].local_tempfile.try :path
    end

    def file_url
      self.meta[:read_url]
    end
    
    def copy_file(remote_path)
      # download the file first if this is a remote path so we can do our asset type magic
      local_tempfile = open(remote_path)
      self.file_name  = file_name_from_url remote_path
      self.content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(local_tempfile.path).split(';').first.to_s
      
      # now write to the bucket since we have all the prerequisite information (content/asset type mainly)
      bucket[base_path] = local_tempfile, self.content_type

      # final bits of meta once we've successfully copied to s3
      self.meta[:content_url] = strip_query_string @file
      self.meta[:read_url] = strip_query_string bucket[base_path].url_for(:read).to_s
      self.file_size = bucket[base_path].local_tempfile.size
      set_asset_type
    end

    def save_file
      become_asset_type
    end

    def delete_file
      bucket[base_path] = nil
    end
  end
end
