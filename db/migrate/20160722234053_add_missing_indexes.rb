class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :herd_assets, [ :parent_asset_id, :assetable_type, :assetable_id, :transform_id ]
    add_index :herd_transforms, [ :name, :assetable_type ]
  end
end
