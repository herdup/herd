module Herd
  module AssetsHelper
    def herd_tag(asset, options={})
      case asset
      when Image
        if options[:bg]
          content_tag(:div,raw('&nbsp;'),options.merge(style:"background-image: url('#{asset.file_url}');"))
        else
          tag(:img,options.merge(src:asset.file_url))
        end
      end
    end
  end
end
