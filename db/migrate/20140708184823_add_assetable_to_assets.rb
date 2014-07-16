class AddAssetableToAssets < ActiveRecord::Migration
  def change
    change_table :herd_assets do |t|
      t.references :assetable, polymorphic: true
      t.integer :position
    end
  end
end
