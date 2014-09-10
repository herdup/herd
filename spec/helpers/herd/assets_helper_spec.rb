require 'spec_helper'

module Herd
  describe AssetsHelper do
    it "should output image tag for image asst" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Asset.create file:path.to_s
      asset = Asset.find asset.id
      expect(helper.herd_tag asset).to match /img/
      expect(helper.herd_tag asset).to match /#{asset.file_url}/
      expect(helper.herd_tag asset, bg: true).to match /background/
      expect(helper.herd_tag asset, bg: true).to match /#{asset.file_url}/
    end

    it "should output image tag for image resize" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Asset.create file:path
      asset = Asset.find asset.id

      # resize first then rotate
      expect(helper.herd_tag asset.t("resize: 300x", 'small').t("rotate: 90>", 'clock')).to match /img/

      expect(Asset.count).to be 3
      expect(Transform.count).to be 2

      # rotate firs then resize
      expect(helper.herd_tag asset.t("rotate: 90>",'clock').t("resize: 300x",'small')).to match /img/

      # no new transforms just assets
      expect(Transform.count).to be 2
      # got some new assets bae
      expect(Asset.count).to be 5

      child = asset.t("rotate: 90>",'clock').t("resize: 300x",'small')

      expect(child.width).to eq 300
    end

    it "should output model's missing image for non-asseted items" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      # make missing asset
      Page.missing_asset = Asset.create file: path

      page = Page.create path: 'testies'

      expect(helper.herd_tag page.asset).to match /guac.png/

      expect(helper.herd_tag page.assets.take).not_to match /guac.png/
    end

  end
end
