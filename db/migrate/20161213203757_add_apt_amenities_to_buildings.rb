class AddAptAmenitiesToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :apt_amenities, :text
    add_column :buildings, :neighborhood, :text
  end
end
