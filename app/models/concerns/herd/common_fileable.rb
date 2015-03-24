module Herd
  module CommonFileable
    extend ActiveSupport::Concern

    included do
      file_field :file_name
      attr_accessor :file
      attr_accessor :delete_original
      
      after_save -> {
        save_file if self.file.present?
      }

      after_destroy :delete_file
    end

    def file_name_from_url(url)
      URI.unescape(File.basename(URI.parse(url).path))
    end

    def file_ext
      File.extname(file_field).tr('.','') rescue ''
    end

    def file_name_wo_ext
      File.basename(file_field,'.*')
    end

    def strip_query_string(url)
      url = URI url
      url.query = nil
      url.to_s
    end

    def unique_tmppath(ext=nil)
      Dir::Tmpname.tmpdir + "/" + "#{file_name_wo_ext}.#{file_ext}"
    end

    def sanitized_classname
      # since this method is used to create paths in both s3/local file systems
      # to maintain consistency in paths between s3/local fs, we need to make sure the polymorphism is resolved
      # before we write to any paths, remote or otherwise 
      set_asset_type 
      type_s = self.type
      type_s ||= self.class.to_s
      type_s.split("::").second.pluralize.downcase
    end

    def prepare_file(input_file)
      case input_file
      when String
        if File.file? input_file
          self.file = File.open input_file
          self.file_name = File.basename input_file
        elsif input_file =~ /\%d/ and first = sprintf(input_file, 1) and File.file? first
          count = 1
          while File.file? sprintf(input_file, count)
            count += 1
          end
          self.file = File.open first
          self.file_name = File.basename first
          self.frame_count = count
        end
      when URI
        prepare_remote_file input_file
      when Pathname
        self.file = input_file.open
        self.file_name = input_file.basename.to_s
      when ActionDispatch::Http::UploadedFile
        self.file_name = input_file.original_filename
      when File
        self.file_name = File.basename(input_file.path)
      end

      self.content_type = get_content_type_for_file self.file
      finalize_file
    end

    def set_asset_type
      return if self.destroyed? # can't update attrs on destroyed/deleted objects
      #raise ArgumentError, 'Asset content_type cannot be nil' if self.content_type.nil?
      
      case self.content_type.split('/').first
      when 'image'
        self.type = 'Herd::Image'
      when 'video'  
        self.type = 'Herd::Video'
      when 'audio'
        self.type = 'Herd::Audio'
      end
    end

    def become_asset_type
      file = nil
      sub = becomes(self.type.constantize)
      sub.did_identify_type
      sub.meta[:frame_count] = self.frame_count unless self.frame_count.nil?
      sub.save    
    end

    def get_content_type_for_file(file)
      FileMagic.new(FileMagic::MAGIC_MIME).file(file.path).split(';').first.to_s
    end

    # define interface methods

    def did_identify_type
      raise NotImplementedError, unimplemented_in_class_error_str
    end

    def base_path
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    def file_path
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    def file_url
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    def prepare_remote_file(url_object)
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    def finalize_file
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    def save_file
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    def delete_file
      raise NotImplementedError, unimplemented_in_module_error_str
    end

    module ClassMethods
      def file_field(sym)
        define_method :file_field do
          send(sym) || send(:file).to_s
        end
      end

      def fileable_directory_fields(block=nil)
        define_method :fileable_directory_fields do
          if block.present?
            block.call(self)
          else
            self.id.to_s
          end
        end
      end
    end

    private 
    def unimplemented_in_class_error_str
      "This method must be implemented in a subclass of Herd:Asset"
    end

    def unimplemented_in_module_error_str
      "This method must be implemented to conform to the common fileable interface"
    end
  end
end
