module Herd
  module CommonFileable
    extend ActiveSupport::Concern

    included do
      file_field :file_name
      attr_accessor :file
      attr_accessor :delete_original
    end

    def file_name_from_url(url)
      URI.unescape(File.basename(URI.parse(url).path))
    end

    def strip_query_string(url)
      url = URI url
      url.query = nil
      url.to_s
    end

    def unique_tmp_path(ext=nil)
      unique_filename = SecureRandom.urlsafe_base64
      unique_filename = "#{unique_filename}.#{ext}" unless ext.nil?
      Dir::Tmpname.tmpdir + "/" + unique_filename
    end

    def sanitized_classname
      type_s = self.type
      type_s ||= self.class.to_s
      type_s.split("::").second.pluralize.downcase
    end

    def become_type
      file = nil
      sub = becomes(type.constantize)
      sub.did_identify_type
      sub.meta[:frame_count] = self.frame_count unless self.frame_count.nil?
      sub.save    
    end

    # define interface methods

    def did_identify_type
      raise NotImplementedError, "implement me in a subclass bae"
    end

    def file_ext
      raise NotImplementedError, "implement me in a submodule bae"
    end

    def file_name_wo_ext
      raise NotImplementedError, "implement me in a submodule bae"
    end

    def file_path
      raise NotImplementedError, "implement me in a submodule bae"
    end

    def file_url
      raise NotImplementedError, "implement me in a submodule bae"
    end

    def copy_file(file_or_url)
      raise NotImplementedError, "implement me in a submodule bae"
    end

    def save_file
      raise NotImplementedError, "implement me in a submodule bae"
    end

    def delete_file
      raise NotImplementedError, "implement me in a submodule bae"
    end

    module ClassMethods
      def file_field(sym)
        define_method :file_field do
          send(sym) || ''
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
  end
end
