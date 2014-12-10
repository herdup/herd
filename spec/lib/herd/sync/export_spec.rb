require 'spec_helper'

describe Herd::Sync::Base do
  it "should make file map with assetable model structure" do

    ap Herd::Asset.all
    page = Herd::Page.create path: 'home'

    exporter = Herd::Sync::ZipExport.new
    map = exporter.folder_map
    expect(map.keys).to include exporter.path_from_class(page.class)
    expect(map.keys.count).to eq Herd::ASSETABLE_MODELS.count
  end

  it "should export zip structure with assetable model and missing" do
    page = Herd::Page.create path: 'home'
    page.assets.create file: Rails.root.join('../../spec/fixtures/guac.png')
    expect(Herd::Asset.master.count).to be 1

    missing_asset = Herd::Page.missing_asset = Herd::Asset.create file: Rails.root.join('../../spec/fixtures/guac.png')
    expect(Herd::Asset.master.count).to be 2

    # second asset with same name should be renamed
    expect(missing_asset.file_name).not_to eq page.asset.file_name

    exporter = Herd::Sync::ZipExport.new
    exporter.generate_seeds_folder

    expect(Dir["#{exporter.seed_path}/**/**.png"].count).to be 2
    expect(Dir["#{exporter.seed_path}/**/_missing"].count).to be > 0
    expect(Dir["#{exporter.seed_path}/**/#{page.assetable_slug}"].count).to be 1
  end

  it "should make a zip with expected files" do
    Herd::Page.missing_asset = Herd::Asset.create file: Rails.root.join('../../spec/fixtures/guac.png')
    exporter = Herd::Sync::ZipExport.new
    exporter.export

    ::Zip::File.open(exporter.zip_path) do |zip|
      expect(zip.glob("**/**.png").count).to be 1
      expect(zip.glob("**/_missing").count).to eq Herd::ASSETABLE_MODELS.count
    end
  end

  it "should export to s3 n stuff" do
    importer = Herd::Sync::S3Export.new 'sweetgreen-seeds-development'
    importer.s3.buckets['sweetgreen-seeds-development'].objects.with_prefix('herd_export_test').delete_all

    Herd::Page.missing_assets.create file: Rails.root.join('../../spec/fixtures/guac.png')
    Post.missing_assets.create file: Rails.root.join('../../spec/fixtures/shutter.jpg')

    post = Post.create title: 'Test 1'
    post.assets.create file: Rails.root.join('../../spec/fixtures/test.mov')

    post = Post.create title: 'Test 2'

    importer.export_s3 'herd_export_test'

    expect(importer.s3.buckets['sweetgreen-seeds-development'].objects.with_prefix('herd_export_test/').count).to be 4
  end

end
