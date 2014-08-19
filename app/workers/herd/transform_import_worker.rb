module Herd
  class TransformImportWorker
    include Sidekiq::Worker

    def perform(path)
      Herd::Config.load_transforms path
    end
  end
end
