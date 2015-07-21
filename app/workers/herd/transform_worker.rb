
module Herd
  class TransformWorker
    # include Sidekiq::Worker
    # include Sidekiq::Status::Worker # Important!

    def perform(child_asset_id, opts={})
      child = Asset.find child_asset_id
      file = child.transform.perform child.parent_asset do |p|
        at p * 100.0, "transcoding"
      end

      child.update file: file
      child.jid = nil

      # if ENV['HERD_LIVE_ASSETS'] == '1'
      #   Redis.new.publish 'assets', AssetSerializer.new(child).to_json
      # end

    # rescue => e
    #   puts e
    end
  end
end
