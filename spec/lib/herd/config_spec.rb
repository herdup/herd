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

    Herd::Config.save_transforms Rails.root.join('tmp/herd-test.yml'), false
    yml = YAML::load_file Rails.root.join 'tmp/herd-test.yml'
    expect(yml['transforms'].count).to be 1

    child2 = child.n 'test.rotated','rotate: 90>'
    expect(child2.height).to be 350

    Herd::Config.save_transforms Rails.root.join('tmp/herd-test.yml'), false
    yml = YAML::load_file Rails.root.join 'tmp/herd-test.yml'
    expect(yml['transforms'].count).to be 2
  end

  it "should re-read transforms saved to yml" do
    path =  Rails.root.join('../../spec/fixtures/guac.png')
    Post.missing_asset = Herd::Asset.create file: path

    child = Post.missing.n 'test.hole','resize: 350x'

    yml_path = Rails.root.join 'tmp/herd-test.yml'

    Herd::Config.save_transforms yml_path, false

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

  it "should nestify hash and deep_merge!" do
    path =  Rails.root.join('../../spec/fixtures/guac.png')
    Post.missing_asset = Herd::Asset.create file: path
    Herd::Page.missing_asset = Herd::Asset.create file: path

    child = Post.missing.n 'test.hole','resize: 350x'
    child2 = Post.missing.n 'test.crop','crop: 350x350+100+0'
    child3 = Herd::Page.missing.n 'hole.2', 'resize: 450x'


    hash = Herd::Config.serialize child.transform, true
    hash2 = Herd::Config.serialize child2.transform, true
    hash3 = Herd::Config.serialize child3.transform, true

    expect(hash.keys.count).to eq 1
    expect(hash2.keys.count).to eq 1
    expect(hash3.keys.count).to eq 1

    hash.deep_merge! hash2
    hash.deep_merge! hash3

    expect(hash.keys.count).to eq 2
    expect(hash['Post'].keys.count).to eq 2
  end

  it "should output nested yml" do
    path =  Rails.root.join('../../spec/fixtures/guac.png')
    Herd::Page.missing_asset = Herd::Asset.create file: path

    post = Post.create title:'test'

    post.assets.create file: path
    path =  Rails.root.join('../../spec/fixtures/test.mov')
    post.assets.create file: path

    child = post.master_assets.to_a.first.n 'test.hole','resize: 350x'
    child2 = post.master_assets.to_a.last.n 'test.hole','resize: 350x'
    child3 = Herd::Page.missing.n 'hole.2', 'crop: 350x350+100+0'

    yml_path = Rails.root.join 'tmp/herd-test.yml'

    Herd::Config.save_transforms yml_path, true

    yml = YAML::load_file Rails.root.join yml_path

    expect(child3.width).to eq 350

    yml['transforms']['Herd::Page']['hole.2']['Magick']['options']['crop']='400x400+50+0'
    # save it
    yml_path.write yml.to_yaml

    # load it
    Herd::Config.load_transforms yml_path

    expect(child3.transform.options['crop']).to eq '400x400+50+0'

    expect(child3.width).to eq 350
    expect(child3.reload.width).to eq 400

    yml['transforms']['Herd::Page']['hole.2']['Magick']['options']['crop']='200x200+150+0'
    # save it
    yml_path.write yml.to_yaml

    # load it
    Herd::Config.load_transforms yml_path, true

    expect(child3.transform.options['crop']).to eq '200x200+150+0'

    expect(child3.width).to eq 400
    expect(child3.reload.width).to eq 400

    expect(Herd::TransformWorker.jobs.size).to eq 1

    Herd::TransformWorker.drain

    expect(child3.width).to eq 400
    expect(child3.reload.width).to eq 200
  end

  it "should respec defaults" do
    Herd::Transform # load up transforms

    Herd::Transform::Magick.defaults = { resize: '320x' }
    Herd::Transform::Ffmpeg.defaults = { resize: '320x', frame_rate: 20 }

    Herd::Transform::Magick.defaults = { resize: '120x' }

    expect(Herd::Transform::Magick.defaults).not_to be_nil
    expect(Herd::Transform.count).to eq 2

    yml_path = Rails.root.join 'tmp/herd-test.yml'

    Herd::Config.save_transforms yml_path

    yml = YAML::load_file Rails.root.join yml_path

    expect(yml['defaults']['Magick'].count).to eq 1
    expect(yml['defaults']['Ffmpeg'].count).to eq 1


    yml['defaults']['Magick']['options']['quality'] = 50

    yml_path.write yml.to_yaml

    Herd::Config.load_transforms yml_path

    path =  Rails.root.join('../../spec/fixtures/guac.png')
    Herd::Page.missing_asset = Herd::Asset.create file: path

    child = Herd::Page.missing.n 'spot'
    expect(child.transform.options).to eq Herd::Transform::Magick.defaults.options
    expect(child.transform.options[:quality]).to eq 50

    path =  Rails.root.join('../../spec/fixtures/test.mov')
    Post.missing_asset = Herd::Asset.create file: path

    child = Post.missing.n 'spot'
    expect(child.transform.options).to eq Herd::Transform::Ffmpeg.defaults
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
