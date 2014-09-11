require 'spec_helper'

describe Herd::Zip::Import do
  it "should import seeds.zip" do
    importer = Herd::Zip::Import.new Rails.root.join('../fixtures/seeds.zip')
    importer.import

    expect(Herd::Asset.count).to be 1
    expect(Herd::Page.missing).not_to be nil
  end
end
