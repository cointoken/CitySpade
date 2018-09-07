class AddNameIndexToPoliticalAreas < ActiveRecord::Migration
  def change
    add_index :political_areas, :short_name
    add_index :political_areas, :long_name
    add_index :political_areas, :second_name
  end
end
