require 'spec_helper'

describe Herd::Sync::Base do
  fixtures :posts

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


    Herd::Page.missing_assets.create file: Rails.root.join('../../spec/fixtures/guac.png')
    Post.missing_assets.create file: Rails.root.join('../../spec/fixtures/shutter.jpg')

    post = Post.find_by_assetable_slug 'Test 1'
    post.assets.create file: Rails.root.join('../../spec/fixtures/test.mov')

    exporter = Herd::Sync::S3Export.new 'herd-testing', 'herd_export_test', true, ENV['HERD_TESTING_AWS_ACCESS_KEY_ID'], ENV['HERD_TESTING_AWS_SECRET_ACCESS_KEY']

    exporter.s3.buckets['herd-testing'].objects.with_prefix('herd_export_test').delete_all

    exporter.export_s3 

    expect(exporter.s3.buckets['herd-testing'].objects.with_prefix('herd_export_test/').count).to be 5

    Herd::Asset.destroy_all

    importer = Herd::Sync::S3Import.new 'herd-testing', 'herd_export_test', ENV['HERD_TESTING_AWS_ACCESS_KEY_ID'], ENV['HERD_TESTING_AWS_SECRET_ACCESS_KEY']

    importer.import_s3

    expect(Post.missing_assets.count).to eq 1
    expect(Herd::Page.missing_assets.count).to eq 1
    expect(Herd::Asset.count).to eq 3

  end
end
