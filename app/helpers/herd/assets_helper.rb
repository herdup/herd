module Herd
  module AssetsHelper

    def assetable_uploader(assetable) 
      form_for [:herd, assetable.assets.new] do |f|
        concat f.hidden_field :assetable_type
        concat f.hidden_field :assetable_id
        concat f.file_field :file
        concat f.submit
      end
    end

    def herd_tag(asset, options={}, &block)
      return unless asset
      asset.generate unless asset.file_name

      options[:data] = { asset_id: asset.id }
      case asset
      when Image
        if options[:bg]
          options[:style] ||= ""
          options[:style] += ";background-image: url('#{asset.file_url}');"
          options[:style] += "width: #{asset.width}px; height: #{asset.height}px;"

          content_tag options.delete(:bg), raw("&nbsp;"), options  do
            capture(&block) if block_given?
          end
        else
          tag(:img,options.merge(src:asset.file_url))
        end
      when Video
        options[:size] ||= "#{asset.width}x#{asset.height}"
        video_tag([asset.file_url], options) 
      end
    end
  end
end
