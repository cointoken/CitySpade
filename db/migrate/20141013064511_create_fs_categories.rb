class CreateFsCategories < ActiveRecord::Migration
  def change
    create_table :fs_categories do |t|
      t.string :name
      t.string :fs_id
      t.string :parent_fs_id

      t.timestamps
    end
  end
end
