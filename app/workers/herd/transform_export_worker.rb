module Herd
  class TransformExportWorker
    # include Sidekiq::Worker

    def perform(path=nil)
      path ||= Rails.root.join 'config/herd.yml'
      Herd::Config.save_transforms path
    end
  end
end
