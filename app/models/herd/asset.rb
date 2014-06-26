module Herd
  class Asset < ActiveRecord::Base
    include Fileable

    attr_accessor :file
    file_field :file_name

    before_create -> {
      prepare_file if file.present?
    }

    after_create -> {
      puts "before create"
      save_file if file.present?
    }
    after_destroy :cleanup_file


    def prepare_file
      case @file
      when String
        if File.file? file
          file_name = File.basename(@file)
          self.file = File.open(@file)
        else
          uri = URI.parse(@file)
          self.file = open(@file)
          self.file_name = File.basename(uri.path)
        end
      when ActionDispatch::Http::UploadedFile
        self.file_name = @file.original_filename
        self.content_type = @file.content_type
      end
      self.file_size = @file.size
      self.content_type ||= FileMagic.new(::FileMagic::MAGIC_MIME).file(@file.path).split(';').first
    end

    def save_file
      File.open(file_path, "wb") { |f| f.write(file.read) }
    end

    def cleanup_file
      FileUtils.rm_f file_path
      if Dir["#{base_path}/*"].empty?
        FileUtils.rm_rf base_path
      end
    end


    def sanitized_classname
    # use the second path chunk for now (i.e. what's after "Rcms::")
    # not ideal but cant figure out an easy way around it
      self.class.to_s.split("::").second.pluralize.downcase
    end

    def fileable_directory_fields
      id.to_s
    end

    def self.fileable_directory_fields(block=nil)
      define_method :fileable_directory_fields do
        pattern = ""
        if block.present?
          pattern << block.call(self)
        else
          pattern << self.id.to_s
        end
      end
    end
  end
end
