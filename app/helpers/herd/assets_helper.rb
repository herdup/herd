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
      when Video
        video_tag(asset.file_url, size:"#{asset.width}x#{asset.height}", autoplay: true, loop:true)
      end
    end
  end
end
