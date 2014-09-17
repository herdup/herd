module Herd
  module Sync
    class Base
      def class_from_path(path)
        path.classify.constantize
      end
      def path_from_class(klass)
        klass.to_s.underscore
      end
    end
  end
end
