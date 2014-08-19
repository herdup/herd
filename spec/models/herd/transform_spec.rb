require 'spec_helper'

module Herd
  describe Transform do
    it "should recreate child assets with tranform has changed" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file: path
      asset = Herd::Asset.find asset.id # hack cuz need type
      child = asset.t "resize: 30x", 'test'

      expect(child.width).to eq 30

      transform = child.transform
      transform.generate_sync = true
      transform.options = {
        resize: '40x'
      }
      transform.save

      expect(child.width).to eq 30 # not transformed yet
      expect(child.reload.width).to eq 40 # reload reveals updated asset
    end

    it "should recreat using queue if sync = false" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file: path
      asset = Herd::Asset.find asset.id # hack cuz need type
      child = asset.t "resize: 30x", 'test'

      expect(child.width).to eq 30

      transform = child.transform
      transform.options = {
        resize:'50x'
      }
      transform.save

      expect(TransformWorker.jobs.size).to eq 1

      TransformWorker.drain

      expect(child.width).to eq 30
      expect(child.reload.width).to eq 50

    end
  end
end
