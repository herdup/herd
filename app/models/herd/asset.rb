module Herd
  class Asset < ActiveRecord::Base
    include Fileable

    attr_accessor :file
    file_field :file_name
    # validates_presence_of :file_name

    attr_accessor :delete_original

    attr_accessor :jid
    attr_accessor :generate_sync

    scope :master, -> {where(parent_asset_id: nil)}
    scope :child, -> {where.not(parent_asset_id: nil)}

    belongs_to :assetable, polymorphic: true

    belongs_to :transform
    has_many :child_transforms, through: :child_assets, source: :transform

    belongs_to :parent_asset, class_name: 'Asset'
    has_many :child_assets, class_name: 'Asset',
                            dependent: :destroy,
                            foreign_key: :parent_asset_id

    fileable_directory_fields -> (a) {
      if a.master?
        ['master']
      else
        [a.parent_asset_id,a.id].map(&:to_s)
      end
    }

    before_save -> {
      self.assetable_type ||= parent_asset.try :assetable_type
      self.assetable_id ||= parent_asset.try :assetable_id

      if file.present? # reupload
        cleanup_file if file_name.present?
        prepare_file
      end
    }

    after_save -> {
      save_file if @file.present?
    }
    after_create -> {
      generate if child? and transform.present? and !@file.present?
    }

    after_destroy :cleanup_file

    delegate :width, to: :meta_struct
    delegate :height, to: :meta_struct

    serialize :meta, Hash
    def meta_struct
      OpenStruct.new meta
    end

    def generate(async=nil)
      #puts "async #{async} herd: #{ENV['HERD_LIVE_ASSETS']} transform.async #{transform.try(:async)}"
      if async || ENV['HERD_LIVE_ASSETS'] == '1' || transform.try(:async)
        self.jid = TransformWorker.perform_async(id, transform.options)
      else
        generate!
      end
    end

    def generate!
      TransformWorker.new.perform(id, transform.options)
      reload
    end

    def reset
      cleanup_file

      hash = {
        file_name: nil,
        file_size: nil,
        content_type: nil,
        meta: nil
      }

      update_attributes hash
    end

    def child_with_transform(transform)
      # first_or_create will generate a child_asset who's parent_asset is inaccessible
      # because it's tainted with the transform_id: transform.id scope for some reason
      hash = {parent_asset:self, transform:transform}
      child = Asset.where(hash).take || Asset.create(hash)

      child.becomes(type.constantize) rescue child
    end

    def t(transform_string, name=nil, async=nil)
      return unless id
      transform = computed_class.default_transform.find_or_create_with_options_string transform_string, name, assetable_type
      transform.async = async
      child_with_transform transform
    end

    def n(name, transform_string=nil, async=nil)
      return unless id
      trans = computed_class.default_transform.find_by(name:name) unless name.nil?
      child = child_with_transform(trans) if trans
      return child || t(transform_string, name, async)
    end

    def prepare_file
      @file = @file.to_s if @file.kind_of? URI::HTTPS

      case @file
      when String
        if File.file? file
          self.file_name = File.basename(@file)
          self.file = File.open(@file)
        else
          self.file_name = URI.unescape(File.basename(URI.parse(@file).path))
          self.meta[:content_url] = @file

          download_file = File.open unique_tmppath,'wb'
          request = Typhoeus::Request.new(@file,followlocation: true)
          request.on_headers do |response|

            if response.effective_url != self.meta[:content_url]
              self.meta[:effective_url] = response.effective_url
            end

            self.file_name = URI.unescape(File.basename(URI.parse(response.effective_url).path))

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
          # testme
        end
      when Pathname
        # test me
        raise "no file found #{self.file}" unless @file.exist?
        self.file_name = @file.basename.to_s
        self.file = @file.open
      when ActionDispatch::Http::UploadedFile
        self.file_name = @file.original_filename
        self.content_type = @file.content_type.to_s
      when File
        self.file_name = File.basename(@file.path)
      end

      raise "no file, possibly bad url #{@file}" unless @file.try(:size)

      # test me
      self.file_size = @file.size
      # tested png
      self.content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(@file.path).split(';').first.to_s
      # tested image / video

      # should class itself try and figure this out?
      mime_parts = content_type.split('/')
      case mime_parts.first
      when 'image'
        self.type = 'Herd::Image'
      when 'video'
        self.type = 'Herd::Video'
      when 'audio'
        self.type = 'Herd::Audio'
      end


      if master? and new_record? # tested
        o_file_name_wo_ext = file_name_wo_ext
        ix = 0
        while File.exist? file_path do
          ix += 1
          self.file_name = "#{o_file_name_wo_ext}-#{ix}.#{file_ext}"
        end
      end
    end

    def save_file
      File.open(file_path(true), "wb") { |f| f.write(file.read) }
      FileUtils.rm file.path if delete_original || file.path.match(Dir.tmpdir)
      @file = nil
      sub = becomes(type.constantize)

      # ugly callback -- should ideally be automatically chained
      # the problem is due to the type change that happened above
      sub.did_identify_type
      sub.save #if changed?
    end

    def did_identify_type
      puts "subclass me bae"
    end

    def computed_class
      self.type.constantize
    end

    def master?
      parent_asset_id.nil?
    end
    def child?
      !master?
    end
  end

end
