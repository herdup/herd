class AddAssetableTypeToTransforms < ActiveRecord::Migration
  def change
    add_column :herd_transforms, :assetable_type, :string
  end
end
