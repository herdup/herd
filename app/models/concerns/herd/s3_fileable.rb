require 'aws-sdk-v1'

module Herd
  module S3Fileable
    extend ActiveSupport::Concern
    include CommonFileable
    
    class Bucket
      class InvalidBucketValueException < ::Exception
      end

      AWS::S3::S3Object.class_eval do
        # we add this to the s3 object since we need to abstract access to local files
        # for herd to be able to perform transforms -- this is where we keep a reference to it for those purposes
        attr_accessor :local_tmpfile

        alias_method :old_delete, :delete
        def delete
          if self.exists?
            if @local_tmpfile && @local_tmpfile.is_a?(Tempfile)
              path = @local_tmpfile.path
              @local_tmpfile.close
              @local_tmpfile.unlink
              # force removal of file since the above commands leave it hanging for the duration of the thread/process
              FileUtils.rm_f path
            end
            old_delete
          end
        end

        def local_tmpfile
          return @local_tmpfile unless @local_tmpfile.nil?
          @local_tmpfile = Tempfile.open('tmp', Dir::Tmpname.tmpdir) do |file|
            file.binmode
            self.read do |chunk|
              file.write(chunk)
            end
            file
          end
        end
      end

      def initialize
        AWS.config access_key_id: Rails.application.secrets.herd_s3_key, secret_access_key: Rails.application.secrets.herd_s3_secret
        @s3 = AWS::S3.new
        @bucket_name = Rails.application.secrets.herd_s3_bucket
        @obj_cache = {}
      end

      def set_obj_cache(key, local_tmpfile=nil)
        obj = @s3.buckets[@bucket_name].objects[key]
        obj.local_tmpfile = local_tmpfile unless local_tmpfile.nil?
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
          self[key].delete
          @obj_cache.delete key
        elsif value.class.in? [File, Tempfile, ActionDispatch::Http::UploadedFile]
          write_url = self[key].url_for(:write, content_type: content_type).to_s
          require 'typhoeus'
          response = Typhoeus::Request.new(write_url, method: :put, body: value.read, headers: { 'content-type' => content_type }).run
          raise response unless response.code == 200
          self[key].acl = :public_read
          puts "Uploaded to: #{key} with content type: #{content_type}"
          set_obj_cache key, value
        else
          raise InvalidBucketValueException.new "file: #{value.class.to_s}, content type: #{content_type}, key: #{key}" 
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
      path_prefix = Rails.application.secrets.herd_s3_path_prefix.to_s
      paths = [Rails.env, sanitized_classname, fileable_directory_fields.join("/"), self.file_name]
      paths.unshift path_prefix unless path_prefix.blank?
      paths.join "/"
    end

    def file_path
      # check if local file exists and return that otherwise download the file 
      bucket[base_path].local_tmpfile.try(:path).presence || ""
    end

    def file_url(cdn_host=ActionController::Base.asset_host.present?)
      if cdn_host
        # we have an asset host, which should be a cdn that is set up to read from the s3 bucket in pretty much any case
        ActionController::Base.helpers.asset_url URI.parse(self.meta[:read_url]).path
      else
        # direct link to s3
        self.meta[:read_url]
      end
    end

    def prepare_remote_file(input_file)
      # download the file first if this is a remote path so we can do our asset type magic
      input_file = input_file.to_s
      self.meta[:content_url] = strip_query_string input_file
      self.file = open input_file
      self.file_name  = file_name_from_url input_file
    end
    
    def finalize_file
      # check if this file exists in s3 at this base_path, and change the path accordingly with an index suffix
      if master? and new_record?
        ix = 0
        o_file_name_wo_ext = file_name_wo_ext
        while bucket[base_path].exists? do
          ix += 1
          self.file_name = "#{o_file_name_wo_ext}-#{ix}.#{file_ext}"
        end
      end

      # now write to the bucket since we have all the prerequisite information (content/asset type mainly)
      bucket[base_path] = self.file, self.content_type

      # final bits of meta once we've successfully copied to s3
      self.file_size = bucket[base_path].local_tmpfile.size

      # read url is the newly uploaded bucket url -- used in file_url for cdn origin downloading purposes
      self.meta[:read_url] = strip_query_string bucket[base_path].url_for(:read).to_s
    end

    def save_file
      # already saved because of a slightly different s3 flow
      # so just become the new type and we're good
      become_asset_type
    end

    def delete_file
      bucket[base_path] = nil
    end
  end
end
