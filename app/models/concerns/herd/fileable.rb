module Herd
  module Fileable
    extend ActiveSupport::Concern
    include CommonFileable

    def base_path(abs=true, fields = nil)
      fields ||= fileable_directory_fields
      parts = ["/uploads", Rails.env, sanitized_classname]
      parts.concat fields
      parts.unshift *[Rails.root,'public'] if abs
      File.join(*parts)
    end

    def file_path(create=nil)
      FileUtils.mkdir_p base_path if create
      File.join base_path, file_field
    end

    def file_url(absolute=ActionController::Base.asset_host.present?)
      relative = File.join base_path(false), file_field
      if absolute
        ActionController::Base.helpers.asset_url relative
      else
        relative
      end
    end

    def copy_file(input_file)
      case input_file
      when String
        if File.file? input_file
          self.file = File.open(input_file)
          self.file_name = File.basename(input_file)
        #TODO: make this work with non-1 starting shnitzeldorfs
        elsif input_file =~ /\%d/ and first = sprintf(input_file, 1) and File.file? first
          count = 1
          while File.file? sprintf(input_file,count)
            count += 1
          end
          self.file = File.open(first)
          self.file_name = File.basename(first)
          self.frame_count = count
        else
          self.meta[:content_url] = strip_query_string input_file
          download_file = File.open unique_tmp_path,'wb'
          request = Typhoeus::Request.new input_file, followlocation: true
          request.on_headers do |response|
            effective_url = strip_query_string response.effective_url
            self.meta[:effective_url] = effective_url if effective_url != self.meta[:content_url]

            self.file_name = file_name_from_url response.effective_url

            if len = response.headers['Content-Length'].try(:to_i)
              @pbar = ProgressBar.new self.file_name, len
              @pbar.file_transfer_mode
            end
          end

          request.on_body do |chunk|
            download_file.write(chunk)
            @pbar.inc chunk.size if @pbar
          end

          request.on_complete do |response|
            download_file.close
          end

          request.run

          self.file = File.open download_file.path
          self.file_name = URI.unescape(File.basename(URI.parse(input_file).path))
        end
      when Pathname
        raise "no file found #{self.file}" unless input_file.exist?
        self.file = input_file.open
        self.file_name = input_file.basename.to_s
      when ActionDispatch::Http::UploadedFile
        self.file_name = input_file.original_filename
      when File
        self.file_name = File.basename(input_file.path)
      end

      self.file_size = file.size
      self.content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(file.path).split(';').first.to_s

      if master? and new_record?
        ix = 0
        o_file_name_wo_ext = file_name_wo_ext
        while File.exist? file_path do
          ix += 1
          self.file_name = "#{o_file_name_wo_ext}-#{ix}.#{file_ext}"
        end
      end

    end

    def save_file
      File.open(file_path(true), "wb") { |f| f.write(file.read) }

      if self.frame_count
        FileUtils.cp_r "#{File.dirname(file.path)}/.", File.dirname(file_path(true))
        FileUtils.rm_rf File.dirname(file.path) if delete_original || file.path.match(Dir.tmpdir)
      else
        FileUtils.rm file.path if delete_original || file.path.match(Dir.tmpdir)
      end

      become_asset_type
    end

    def delete_file
      FileUtils.rm_f file_path if File.exist? file_path
      # cleanup empty folders like a nice boy
      fields = fileable_directory_fields
      while fields.present? do
        path = base_path true, fields
        FileUtils.rm_rf path if Dir["#{path}/*"].empty?
        fields.pop
      end
    end
  end
end
