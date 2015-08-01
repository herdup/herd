module Herd
  class TransformImportWorker
    # include Sidekiq::Worker

    def perform(path, async=nil)
      Herd::Config.load_transforms path, async
    end
  end
end
