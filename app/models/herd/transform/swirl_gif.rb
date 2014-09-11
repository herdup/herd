module Herd
  class Transform::SwirlGif < Transform
    def perform(asset, options)
      iterate = self.options.extract!(:step,:start,:end)
      transforms = (iterate[:start]..iterate[:end]).to_a.map do |ix|
        "swirl: -#{ix*iterate[:step]}"
      end

      # dont need to use child assets here necessarily
      children = transforms.each_with_index.map do |t,ix|
        asset.t(t, position:ix)
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

      # FileUtils.rm_rf(out_dir)
      gif_path
    end
  end
end
