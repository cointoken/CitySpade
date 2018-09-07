class AddStateToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :state, :string
    remove_column :buildings, :borough, :string
    remove_column :buildings, :police_prct, :integer
    remove_column :buildings, :fire_comp, :string
    remove_column :buildings, :school_dist, :integer
    remove_column :buildings, :garage_area, :integer
    remove_column :buildings, :retail_area, :integer
    remove_column :buildings, :office_area, :integer
  end
end
