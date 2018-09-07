class AddSecondNameToPoliticalAreas < ActiveRecord::Migration
  def change
    add_column :political_areas, :second_name, :string, limit: 20
  end
end
