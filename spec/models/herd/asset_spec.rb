require 'spec_helper'

module Herd
  describe Asset do
    it "should create image asset from Pathname" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file: path

      expect(File).to exist(asset.file_path)
      expect(asset.type).to eq('Herd::Image')
      asset = Asset.find asset.id
      expect(asset.class).to eq Herd::Image
    end

    it "should create image asset from filename" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file:path.to_s

      expect(File).to exist(asset.file_path)
      expect(asset.type).to eq('Herd::Image')
      asset = Asset.find asset.id
      expect(asset.class).to eq Herd::Image
      expect(asset.content_type).to eq('image/png')

      asset = Herd::Asset.create file: path.to_s
      expect(asset.file_name).not_to be path.basename.to_s
    end

    it "should not dupe if same file_name uploaded twice" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset1 = Herd::Asset.create file:path.to_s
      asset2 = Herd::Asset.create file: path.to_s
      expect(asset1.file_name).not_to be asset2.file_name
    end

    it "should create image asset from url" do
      asset = Herd::Asset.create file: 'http://files.ginlane.com/photo.JPG'

      expect(File).to exist(asset.file_path)
      expect(asset.type).to eq('Herd::Image')
      asset = Asset.find asset.id
      expect(asset.class).to eq Herd::Image
    end

    it "should fail if bad path" do
      asset = Herd::Asset.new file: Rails.root.join('/etc/poop.png')
      expect{ asset.save }.to raise_error
    end

    it "should create video asset from url" do
      asset = Herd::Asset.create file: 'http://files.ginlane.com/herd/IMG_6243.m4v'
      expect(File).to exist asset.file_path
      expect(asset.type).to eq 'Herd::Video'
      expect(asset.content_type).to eq 'video/mp4'
    end

    it "should replace original file if another is set" do
      asset = Herd::Asset.create file: 'http://files.ginlane.com/photo.JPG'
      file_path1 = asset.file_path
      expect(File).to exist file_path1
      asset.update file: Rails.root.join('../../spec/fixtures/guac.png')
      expect(File).not_to exist file_path1
      expect(File).to exist asset.file_path
    end

    it "should create child asset with transform string" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file: path
      asset = Herd::Asset.find asset.id # hack cuz need type
      child = asset.t("resize: 30x", 'test')
      expect(child.width).to eq 30
    end

    it "should be able to chain transform strings" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file: path
      asset = Herd::Asset.find asset.id # hack cuz need type
      child = asset.t("resize: 30x", 'test')
      expect(child.width).to eq 30
      child2 = child.t("rotate: 90>", 'rotate-clockwise')
      expect(child2.height).to eq 30
    end

    it "should created empty child if async flag true" do
      path =  Rails.root.join('../../spec/fixtures/guac.png')
      asset = Herd::Asset.create file: path
      asset = Herd::Asset.find asset.id

      child = asset.t 'resize: 300x', 'small', true
      expect(child.file_name).to be_nil


    end

  end
end
