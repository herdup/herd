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

    def set_asset_type
      return if self.destroyed? # can't update attrs on destroyed/deleted objects
      raise ArgumentError, 'Asset content_type cannot be nil' if self.content_type.nil?
      
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

    def copy_file(file_or_url)
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
