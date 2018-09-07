class AddStatusToPoliticalAreas < ActiveRecord::Migration
  def change
    add_column :political_areas, :enabled, :boolean, default: true
  end
end
