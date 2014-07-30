module Herd
  class TransformSerializer < ActiveModel::Serializer
    attributes :id, :created_at, :type
    attributes :options

    def options
      YAML::dump(object.options).split("\n").drop(1).join('|')
    end
    def _format
      object.format
    end

    def resize
      object.options.try :resize
    end

  end
end
