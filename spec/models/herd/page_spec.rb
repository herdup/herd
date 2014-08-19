require 'spec_helper'

module Herd
  describe Page do
    it "should allow assets to be attached " do
      page = Herd::Page.create path: '/'
      asset = page.assets.create file: Rails.root.join('../../spec/fixtures/guac.png')
      # bug?:
      page.assets.reload # because becomes makes two objects in relation - reload makes 1
      # expected but annoying
      asset = Herd::Asset.find asset.id # makes it proper Herd::Image class

      expect(asset.class).to be Herd::Image

      # make a resize
      child = asset.t("resize: 300x", nil, false)

      # should resize right
      expect(child.width).to eq 300

      # should have made a transform
      expect(Herd::Page.transforms.count).to be 1

      # assets relation should be scoped to masters
      expect(page.assets.count).to be 1
      # all assets should give resize as well
      expect(page.all_assets.count).to be 2 # with resize
    end

    it "should allow missing asset to be set on page" do
      asset = Herd::Page.missing_asset = Asset.create file: Rails.root.join('../../spec/fixtures/guac.png')

      expect(asset.id).to_not be_nil

      expect(Herd::Page.missing.id).to be asset.id


      child = Herd::Page.missing.t("resize: 320x")

      expect(Herd::Asset.count).to be 2

      expect(Herd::Page.missing_assets.count).to be 1
      expect(Herd::Page.missing_assets.unscoped.count).to be 2
    end


  end
end
