class CreateHerdTransforms < ActiveRecord::Migration
  def change
    create_table :herd_transforms do |t|
      t.string :type
      t.text :options
      t.timestamps
    end
    add_column :herd_assets, :transform_id, :integer
  end
end
