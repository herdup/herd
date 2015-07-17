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
    importer = Herd::Sync::S3Import.new 'herd-testing', 'herd_import_test', ENV['HERD_TESTING_AWS_ACCESS_KEY_ID'], ENV['HERD_TESTING_AWS_SECRET_ACCESS_KEY']
    importer.import_s3

    expect(post.assets.count).to eq 1
  end
end
