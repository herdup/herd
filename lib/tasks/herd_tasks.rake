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
      Herd::TransformImportWorker.perform_async Rails.root.join 'config/herd.yml'
    end
  end

  task :generate, [:async] => [:environment] do |t,args|
    args.with_defaults(:async => false)

    Herd::Transform.all.map do |t|
      Herd::Asset.master.where(assetable_type:t.assetable_type).map do |a|
        t.async = args.async
        child = a.child_with_transform t
      end
    end
  end
end

Rake::Task["db:reset"].enhance ['herd:cleanup']
Rake::Task["db:drop"].enhance ['herd:cleanup']
