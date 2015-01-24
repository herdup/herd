module Herd
  class Text < Asset

    def self.default_transform
      Herd::Transform::Render
    end

    def did_identify_type

    end

    def load_meta

    end


    def content
      File.read file_path
    end

  end
end
