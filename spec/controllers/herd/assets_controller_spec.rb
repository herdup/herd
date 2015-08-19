require 'spec_helper'

module Herd
  describe AssetsController do
    fixtures :posts

    it "prepares asset_params if only assetable_slug is passed" do
    
      controller.params[:asset] = {
        "assetable_type" => "Post",
        "assetable_slug" => "Test 1",
        "file" => {}
      } 
      
      asset_params = controller.send(:asset_params)
      expect(asset_params[:assetable_id]).to be Post.first.id 
    end
  end
end
