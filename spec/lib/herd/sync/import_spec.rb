require 'spec_helper'

describe Herd::Sync::Base do
  it "should import seeds.zip" do
    importer = Herd::Sync::ZipImport.new Rails.root.join('../fixtures/seeds.zip')
    importer.import

    expect(Herd::Asset.count).to be 1
    expect(Herd::Page.missing).not_to be nil
  end

  it "should import seeds from s3" do
    post = Post.create title: 'Test 1'
    importer = Herd::Sync::S3Import.new 'sweetgreen-seeds-development', 'herd_import_test'
    importer.import_s3

    expect(post.assets.count).to eq 1
  end
end
