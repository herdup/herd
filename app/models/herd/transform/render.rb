module Herd
  class Transform::Render < Transform
    def perform(asset,options)
      asset.unique_tmppath(nil, 'html').tap do |out|
        File.open(out, 'w') do |f|
          f.write Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true).render(asset.content)
        end
      end
    end
  end
end
