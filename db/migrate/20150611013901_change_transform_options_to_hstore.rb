class ChangeTransformOptionsToHstore < ActiveRecord::Migration
  def up
    enable_extension 'hstore'
    change_column :herd_transforms, :options, 'hstore USING null'
  end

  def down
    disable_extension 'hstore'
    change_column :herd_transforms, :options, 'text USING null'
  end
end
