module Herd
  module Zip
    class Export < Base
      attr_accessor :seed_path
      attr_accessor :zip_path
      attr_accessor :output_assets

      def initialize(seed_path=nil,zip_path=nil, output_assets=true)
        @seed_path ||= Rails.root.join 'tmp/seeds'
        @zip_path = zip_path || Rails.root.join('public/seeds.zip')
        @output_assets = output_assets
      end

      def folder_map
        # loop through all assetable models and build hash of :slug
        folder_map = Herd::ASSETABLE_MODELS.inject({}) do |h,model|
          # convert module structure to path structure
          path = path_from_class model
          # populate hash with array of slugs; return hash
          h[path] = model.group(model.assetable_slug_column).map(&:assetable_slug); h
        end
      end

      def generate_seeds_folder(pre_clean=true)
        FileUtils.rm_rf @seed_path if pre_clean
        # build folder structure into seed_path
        folder_map.each do |class_path,assetables|

          assetable_path = File.join @seed_path, class_path, '_missing'
          FileUtils.mkdir_p assetable_path

          klass = class_from_path class_path
          if klass.missing.present?
            a = klass.missing
            FileUtils.cp a.file_path, File.join(assetable_path, a.file_name)
          end

          assetables.each do |slug|
            assetable_path = File.join @seed_path, class_path, slug
            # make a directory for each assetable item's slug
            FileUtils.mkdir_p assetable_path

            # copy the object's assets into their seed folder
            if @output_assets
              object = class_from_path(class_path).find_by_assetable_slug slug
              object.assets.master.each do |a|
                FileUtils.cp a.file_path, File.join(assetable_path, a.file_name)
              end
            end
          end
        end
      end

      def zip_folder(source_path, zip_path)
        # make sure no existing zip
        FileUtils.rm_rf zip_path
        # open new zip at destination path
        ::Zip::File.open(zip_path, ::Zip::File::CREATE) do |zip|
          # glob folder structure
          # FIXME: cleanup metafiles
          Dir["#{source_path}/**/**"].each do |file|
            relative = file.gsub("#{source_path}/", '')
            # add file to zip, first make path relative
            zip.add relative, file
          end
        end
      end

      def export
        generate_seeds_folder
        zip_folder @seed_path, @zip_path
      end
    end
  end
end
