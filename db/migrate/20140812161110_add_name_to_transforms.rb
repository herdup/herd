class AddNameToTransforms < ActiveRecord::Migration
  def change
    add_column :herd_transforms, :name, :string
  end
end
