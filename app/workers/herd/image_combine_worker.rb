module Herd
class ImageCombineWorker
  include Sidekiq::Worker

  def perform(asset_id, transform_id)
    asset = Asset.find_by(id:asset_id)#.t("crop: '34%x100%+52+0'")
    transforms = (1..5).to_a.map do |ix|
      "swirl: -#{ix*10}"
    end
    children = transforms.each_with_index.map do |t,ix|
      child.t(t, position:ix)
    end
    tmp_dir = Dir::Tmpname.tmpdir
    out_dir = File.join(tmp_dir,asset.file_name_wo_ext)
    FileUtils.rm_rf(out_dir)
    FileUtils.mkdir_p(out_dir)
    children.each_with_index do |a, ix|
      out_path = File.join(out_dir,"#{a.file_name_wo_ext}_#{ix}.#{a.file_ext}")
      FileUtils.cp(a.file_path, out_path)
    end
    children.reverse.drop(1).each_with_index do |a, ix|
      out_path = File.join(out_dir,"#{a.file_name_wo_ext}_#{children.count+ix}.#{a.file_ext}")
      FileUtils.cp(a.file_path, out_path)
    end
    gif_path = "#{out_dir}/#{asset.file_name_wo_ext}.gif"
    `convert -delay 1 #{out_dir}/*.jpg #{gif_path}`
    child = asset.child_assets.create file: gif_path, transform_id: transform_id
    # FileUtils.rm_rf(out_dir)
    child
  end
end
end
