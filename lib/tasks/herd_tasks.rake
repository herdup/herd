# desc "Explaining what the task does"
namespace :herd do

  desc "Remove public/assets folder"
  task :cleanup do
    FileUtils.rm_rf File.join(Rails.root, 'public', 'uploads')
  end

  task watch: :environment do
    Herd::Config.new.watch
  end

  namespace :config do
    task import: :environment do |t,args|
      args.with_defaults(:async => false)

      Herd::TransformImportWorker.new.perform Rails.root.join 'config/herd.yml', args.async
    end
    task export: :environment do |t,args|
      Herd::TransformExportWorker.new.perform Rails.root.join 'config/herd.yml'
    end
  end

  task :generate, [:async] => [:environment] do |t,args|
    args.with_defaults(:async => false)

    Herd::Asset.master.where.not(assetable:nil).map do |a|
      a.assetable.transforms.each do |t|
        t.async = args.async
        a.child_with_transform t
      end if a.assetable
    end
  end
end

Rake::Task["db:reset"].enhance ['herd:cleanup']
Rake::Task["db:drop"].enhance ['herd:cleanup']
