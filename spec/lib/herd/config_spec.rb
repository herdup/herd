require 'spec_helper'

describe Herd::Config do
  it "should load transforms from yml" do
    path =  Rails.root.join('../../spec/fixtures/herd-example.yml')
    Herd::Config.load_transforms path

    expect(Herd::Transform.count).to be 3
    expect(Post.transforms.count).to be 3
  end

  it "should save new transforms to yml" do
    path =  Rails.root.join('../../spec/fixtures/guac.png')
    Post.missing_asset = Herd::Asset.create file: path

    child = Post.missing.n 'test.hole','resize: 350x'

    expect(child.width).to be 350
    expect(Herd::Transform.count).to be 1

    Herd::Config.save_transforms Rails.root.join 'tmp/herd-test.yml'
    yml = YAML::load_file Rails.root.join 'tmp/herd-test.yml'
    expect(yml['transforms'].count).to be 1

    child2 = child.n 'test.rotated','rotate: 90>'
    expect(child2.height).to be 350

    Herd::Config.save_transforms Rails.root.join 'tmp/herd-test.yml'
    yml = YAML::load_file Rails.root.join 'tmp/herd-test.yml'
    expect(yml['transforms'].count).to be 2
  end

  it "should re-read transforms saved to yml" do
    path =  Rails.root.join('../../spec/fixtures/guac.png')
    Post.missing_asset = Herd::Asset.create file: path

    child = Post.missing.n 'test.hole','resize: 350x'

    yml_path = Rails.root.join 'tmp/herd-test.yml'

    Herd::Config.save_transforms yml_path

    yml = YAML::load_file Rails.root.join yml_path

    tran_h = yml['transforms'].first

    # causally check some equality
    expect(tran_h['options']).to eq Herd::Transform.options_from_string('resize: 350x').to_h

    # change yml
    tran_h['options']['quality'] = 80

    # save it
    yml_path.write yml.to_yaml

    # load it
    Herd::Config.load_transforms yml_path

    # check it
    expect(child.transform.options).to eq tran_h['options']
  end

  # it "should watch file for changes and sync db!" do
  #   path =  Rails.root.join('../../spec/fixtures/guac.png')
  #   Post.missing_asset = Herd::Asset.create file: path
  #   child = Post.missing.n 'test.hole','resize: 350x'
  #
  #   yml_path = Rails.root.join 'tmp/herd-test.yml'
  #   config = Herd::Config.new yml_path
  #
  #   watch_thread = Thread.new do
  #     config.watch true
  #   end
  #
  #   yml = YAML::load_file Rails.root.join yml_path
  #
  #   tran_h = yml['transforms'].first
  #   tran_h['options']['quality'] = 80
  #
  #   # save it
  #   yml_path.write yml.to_yaml
  #
  #   watch_thread.join
  #
  #
  #   expect(Post.missing.transform.options[:quality]).to eq 80
  #
  #   # watch_thread.raise IOError.new
  # end
end
