require 'spec_helper'

module Herd
  describe Asset do
    let :img_path do
      Rails.root.join('../../spec/fixtures/guac.png')
    end

    it "should create image asset from Pathname" do
      asset = Herd::Asset.create file: img_path

      expect(File).to exist(asset.file_path)
      expect(asset.type).to eq('Herd::Image')
      asset = Asset.find asset.id
      expect(asset.class).to eq Herd::Image
    end

    it "should create image asset from filename" do
      asset = Herd::Asset.create file:img_path.to_s

      expect(File).to exist(asset.file_path)
      expect(asset.type).to eq('Herd::Image')
      asset = Asset.find asset.id
      expect(asset.class).to eq Herd::Image
      expect(asset.content_type).to eq('image/png')

      asset = Herd::Asset.create file: img_path.to_s
      expect(asset.file_name).not_to be img_path.basename.to_s
    end

    it "should not dupe if same file_name uploaded twice" do
      asset1 = Herd::Asset.create file: img_path.to_s
      asset2 = Herd::Asset.create file: img_path.to_s
      expect(asset1.file_name).not_to be asset2.file_name
    end

    it "should create image asset from url" do
      asset = Herd::Asset.create file: URI.parse('https://s3.amazonaws.com/herd-testing/resources/photo.jpg')

      expect(File).to exist(asset.file_path)
      expect(asset.type).to eq('Herd::Image')
      asset = Asset.find asset.id
      expect(asset.class).to eq Herd::Image
    end

    it "should fail if bad path" do
      asset = Herd::Asset.new file: Rails.root.join('/etc/no_file_here.png')
      expect{ asset.save }.to raise_error
    end

    it "should create video asset from url" do
      asset = Herd::Asset.create file: URI.parse('https://s3.amazonaws.com/herd-testing/resources/video.m4v')
      expect(File).to exist asset.file_path
      expect(asset.type).to eq 'Herd::Video'
      expect(asset.content_type).to eq 'video/mp4'
    end

    it "should replace original file if another is set" do
      asset = Herd::Asset.create file: URI.parse('https://s3.amazonaws.com/herd-testing/resources/photo.jpg')
      file_path1 = asset.file_path
      expect(File).to exist file_path1
      asset.update file: img_path
      expect(File).not_to exist file_path1
      expect(File).to exist asset.file_path
    end

    it "should create child asset with transform string" do
      asset = Herd::Asset.create file: img_path
      asset = Herd::Asset.find asset.id # hack cuz need type
      child = asset.t("resize: 30x", 'test')
      expect(child.width).to eq 30
    end

    it "should be able to chain transform strings" do
      asset = Herd::Asset.create file: img_path
      asset = Herd::Asset.find asset.id # hack cuz need type
      child = asset.t("resize: 30x", 'test')
      expect(child.width).to eq 30
      child2 = child.t("rotate: 90>", 'rotate-clockwise')
      expect(child2.height).to eq 30
    end

    xit "should created empty child if async flag true" do
      asset = Herd::Asset.create file: img_path
      asset = Herd::Asset.find asset.id

      child = asset.t 'resize: 300x', 'small', true
      expect(child.file_name).to be_nil
    end
  end
end
