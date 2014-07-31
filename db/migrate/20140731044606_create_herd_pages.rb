class CreateHerdPages < ActiveRecord::Migration
  def change
    create_table :herd_pages do |t|
      t.string :path

      t.timestamps
    end
  end
end
