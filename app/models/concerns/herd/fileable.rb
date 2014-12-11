module Herd::Fileable
	extend ActiveSupport::Concern

	def base_path(abs=true)
	  path_with_fields fileable_directory_fields, abs
	end

	def path_with_fields(fields, abs=true)
		parts = ["/uploads", Rails.env, sanitized_classname]
		parts.concat fields
		parts.unshift *[Rails.root,'public'] if abs
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

	def file_path(create=nil)
		FileUtils.mkdir_p base_path if create
		File.join base_path, file_field
	end

	def file_url(absolute=ActionController::Base.asset_host.present?)
		relative = File.join base_url, file_field
		if absolute
			ActionController::Base.helpers.asset_url relative
		else
			relative
		end
	end

	def file_exists?
	  File.exists? file_path
	end

	def unique_tmppath(seed=nil,ext=nil)
	  ext  ||= file_ext
	  seed ||= file_name_with_ext(ext)
		Dir::Tmpname.tmpdir + "/" + seed
	end

	def sanitized_classname
		# use the second path chunk for now (i.e. what's after "Rcms::")
		# not ideal but cant figure out an easy way around it
		type_s = self.type
		type_s ||= self.class.to_s
		type_s.split("::").second.pluralize.downcase
	end

	def cleanup_file
		FileUtils.rm_f file_path if File.exist? file_path

		# cleanup empty folders like a nice boy
		fields = fileable_directory_fields
		while fields.present? do
			path = path_with_fields fields
			FileUtils.rm_rf path if Dir["#{path}/*"].empty?
			fields.pop
		end
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
