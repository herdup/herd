require 'spec_helper'

module Herd
  describe TransformWorker do

    it "should take an empty child asset and fill it" do
      asset = Herd::Asset.create file: 'http://files.ginlane.com/herd/IMG_6243.m4v'
      asset = Herd::Asset.find asset.id

      child = asset.t 'resize: 300x', 'small', true

      expect(child.file_name).to be_nil

      expect(TransformWorker.jobs.size).to eq 1
      
      TransformWorker.drain
      # still nil because needs reload
      expect(child.file_name).to be_nil
      expect(child.reload.file_name).not_to be_nil
      expect(child.width).to eq 300
    end
  end
end
