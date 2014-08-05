# desc "Explaining what the task does"
namespace :herd do
  desc "Remove public/assets folder"
  task :cleanup do
    FileUtils.rm_rf File.join(Rails.root, 'public', 'uploads')
  end
end

Rake::Task["db:reset"].enhance ['herd:cleanup']
Rake::Task["db:drop"].enhance ['herd:cleanup']
