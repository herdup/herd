module Herd
  module Assetable
    extend ActiveSupport::Concern

    included do
      has_many :assets, as: :assetable, class_name: 'Herd::Asset'
    end

    module ClassMethods

    end
  end
end
