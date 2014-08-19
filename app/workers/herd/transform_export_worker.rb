module Herd
  class TransformExportWorker
    include Sidekiq::Worker

    def perform(path=nil)
      Herd::Config.save_transforms path
    end
  end
end
