class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :herd_assets, :parent_asset_id
    add_index :herd_assets, :assetable_type
    add_index :herd_assets, :assetable_id
    add_index :herd_assets, :transform_id
    add_index :herd_transforms, :name
    add_index :herd_transforms, :assetable_type 
  end
end
