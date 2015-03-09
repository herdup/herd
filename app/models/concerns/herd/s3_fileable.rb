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
        attr_accessor :local_tempfile

        alias_method :old_delete, :delete
        def delete
          if @local_tempfile && @local_tempfile.is_a?(Tempfile)
            @local_tempfile.close
            @local_tempfile.unlink
            # force removal of file since the above commands leave it hanging for the duration of the thread/process
            FileUtils.rm_f @local_tempfile.path
          end
          old_delete
        end

        def local_tempfile
          return @local_tempfile unless @local_tempfile.nil?
          @local_tempfile = Tempfile.open('tmp', Dir::Tmpname.tmpdir) do |file|
            file.binmode
            self.read do |chunk|
              file.write(chunk)
            end
            file
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
          obj = self[key]
          obj.delete
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
      [Rails.application.secrets.current_tenant, Rails.env, sanitized_classname, fileable_directory_fields.join("/"), self.file_name].join("/")
    end

    def file_path
      # check if local file exists and return that otherwise download the file 
      bucket[base_path].local_tempfile.try(:path).presence || ""
    end

    def file_url
      self.meta[:read_url]
    end
    
    def copy_file(input_file)
      case input_file
      when String
        # download the file first if this is a remote path so we can do our asset type magic
        self.meta[:content_url] = strip_query_string input_file
        self.file = open input_file
        self.file_name  = file_name_from_url input_file
      when Pathname
        self.file = input_file.open
        self.file_name = input_file.basename.to_s 
      when ActionDispatch::Http::UploadedFile
        self.file_name = input_file.original_filename
      when File
        self.file_name = File.basename(input_file.path)
      end

      self.content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(self.file.path).split(';').first.to_s

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
      self.file_size = bucket[base_path].local_tempfile.size

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
