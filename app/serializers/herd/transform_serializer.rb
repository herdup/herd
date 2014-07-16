module Herd
  class TransformSerializer < ActiveModel::Serializer
    attributes :id, :created_at, :updated_at, :type
    attribute :_options, key: :options


    def _options
      YAML::dump(object.options)
    end
    def _format
      object.format
    end

    def resize
      object.options.try :resize
    end



  end
end
