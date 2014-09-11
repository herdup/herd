require 'spec_helper'

describe Herd::Zip::Export do
  it "should make file map with assetable model structure" do

    ap Herd::Asset.all
    page = Herd::Page.create path: 'home'

    exporter = Herd::Zip::Export.new
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

    exporter = Herd::Zip::Export.new
    exporter.generate_seeds_folder

    expect(Dir["#{exporter.seed_path}/**/**.png"].count).to be 2
    expect(Dir["#{exporter.seed_path}/**/_missing"].count).to be > 0
    expect(Dir["#{exporter.seed_path}/**/#{page.assetable_slug}"].count).to be 1
  end

  it "should make a zip with expected files" do
    Herd::Page.missing_asset = Herd::Asset.create file: Rails.root.join('../../spec/fixtures/guac.png')
    exporter = Herd::Zip::Export.new
    exporter.export

    ::Zip::File.open(exporter.zip_path) do |zip|
      expect(zip.glob("**/**.png").count).to be 1
      expect(zip.glob("**/_missing").count).to eq Herd::ASSETABLE_MODELS.count
    end
  end

end
