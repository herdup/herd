
module Herd
  class TransformWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker # Important!

    def perform(child_asset_id, opts={})
      child = Asset.find child_asset_id

      @pbar = ProgressBar.new child.parent_asset.file_name, 100

      file = child.transform.perform child.parent_asset, child.transform.options_with_defaults do |p|
        p *= 100.0
        at p, "transcoding"
        @pbar.set(p) unless p > 100
      end

      child.update file: file
      child.jid = nil

      Redis.new.publish 'assets', AssetSerializer.new(child).to_json

    rescue Redis::CannotConnectError => e
      puts e
    end
  end
end
