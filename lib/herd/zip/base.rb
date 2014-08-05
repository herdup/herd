module Herd
  module Zip
    class Base
      def class_from_path(path)
        path.split('/').join('::').constantize
      end
      def path_from_class(klass)
        klass.to_s.split('::').join '/'
      end
    end
  end
end
