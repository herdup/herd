module Herd
  module Sync
    class Base
      attr_accessor :accept_extensions

      def accept_extensions
        @accept_extensions ||= %w(.jpg .jpeg .gif .png .mp4 .mov .webm .m4v .tif .md)
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



      def class_from_path(path)
        path.classify.constantize
      end
      def path_from_class(klass)
        klass.to_s.underscore
      end
    end
  end
end
