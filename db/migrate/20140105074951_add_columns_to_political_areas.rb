class AddColumnsToPoliticalAreas < ActiveRecord::Migration
  def change
    add_column :political_areas, :lft, :integer
    add_column :political_areas, :rgt, :integer
    add_column :political_areas, :depth, :integer
    add_index  :political_areas, :lft
    add_index  :political_areas, :rgt
    add_index :political_areas, :parent_id
    PoliticalArea.rebuild!
  end
end
