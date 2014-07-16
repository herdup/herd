class CreateHerdAssets < ActiveRecord::Migration
  def change
    create_table :herd_assets do |t|
      t.string :file_name
      t.integer :file_size
      t.string :content_type
      t.string :type
      t.text :meta
      t.integer :parent_asset_id, index: true

      t.timestamps
    end
  end
end
