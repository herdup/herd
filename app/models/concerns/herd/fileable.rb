module Herd::Fileable
	extend ActiveSupport::Concern

	def base_path(abs=true)
	  parts = ["/uploads", sanitized_classname, fileable_directory_fields]
	  parts.unshift [Rails.root,'public'] if abs
	  File.join(*parts)
	end

	def base_url
	  base_path false
	end

	def file_ext
	  File.extname(file_field).tr('.','') rescue ''
	end

	def file_name_wo_ext
		File.basename(file_field,'.*')
	end

	def file_name_with_ext(ext)
	  "#{file_name_wo_ext}.#{ext}"
	end

	def path_with_ext(ext)
	  File.join(base_path, file_name_with_ext(ext))
	end

	def filename=(filename)
		@filename = filename
	end

  def filename
    if @filename.nil?
      @filename = Pathname.new(file_field).basename.to_s
    end
    @filename
  end

	def file_path
	  if @file_path.nil?
	    base = base_path
	    unless File.exists? base
	    	FileUtils.mkdir_p base
	    	FileUtils.chmod 0775, base
	    end
	    @file_path = "#{base}/#{filename}"
	  end
	  @file_path
	end

	def file_url
	  if @file_url.nil?
	    base = base_url
	    @file_url = "#{base}/#{filename}"
	  end
	  @file_url
	end

	def file_exists?
	  File.exists? file_path
	end

	def unique_tmppath(ext=nil)
	  ext  ||= file_ext
	  seed ||= file_name_with_ext(ext)
		Dir::Tmpname.tmpdir + "/" + seed
	end

	def writeable_tempfile(ext=nil)
		# @DEPRECATED: use unique_tmppath -- no reason to make files... yet
	  ext  ||= file_ext
	  seed ||= file_name_with_ext(ext)
	  @tempfile = Tempfile.new([File.basename(seed, '.*'), File.extname(seed)])
	  @tempfile.binmode
	  @tempfile
	end

	module ClassMethods
		def file_field(sym)
			define_method :file_field do
				send(sym)
			end
		end
	end

end
