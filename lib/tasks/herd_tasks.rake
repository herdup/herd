# desc "Explaining what the task does"
# task :herd do
#   # Task goes here
# end
namespace :herd do
  task :export_zip => :environment do
    folders = Herd::ASSETABLE_MODELS.inject({}) do |h,t|
      path = t.to_s.split('::').join('/')
      h[path] = t.group(:slug).map(&:slug); h
    end

    seed_struct = Rails.root.join('tmp','seed')
    FileUtils.rm_rf seed_struct
    folders.each do |f,a|
      a.each do |s|
        FileUtils.mkdir_p Rails.root.join('tmp','seed',f,s)
      end
    end
    zip_file = Rails.root.join('public','seed.zip')
    FileUtils.rm_rf zip_file
    Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
      Dir["#{seed_struct}/**/**"].each do |file|
        zip.add file.gsub("#{seed_struct}/", ''), file
      end
    end
  end
  task :import_zip => :environment do
    zip_file = Rails.root.join('public','seed.zip')

    Zip::File.open(zip_file) do |zip|
      zip.each do |entry|
        next if entry.name =~ /\.DS_Store|__MACOSX|(^|\/)\._/
        next unless File.extname(entry.name).downcase == '.jpg'

        puts entry.name

        parts = entry.name.split '/'
        parts.shift if parts.first == 'seed'
        item, asset = *parts.slice!(-2,2)
        modules = parts.join('::')
        klass = modules.constantize
        raise "no class Herd::#{model}" unless klass
        object = klass.friendly.find item
        raise "no item found #{item}" unless object
        asset_path = Rails.root.join('tmp','seed',*parts,item,asset)

        # do something if exists?
        FileUtils.rm asset_path if File.exist? asset_path
        entry.extract(asset_path)
        object.assets.create file: asset_path.to_s
      end
    end
  end
end
