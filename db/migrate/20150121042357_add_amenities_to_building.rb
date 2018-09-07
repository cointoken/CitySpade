class AddAmenitiesToBuilding < ActiveRecord::Migration
  def change
    add_column :buildings, :amenities, :string, limit: 2000
  end
end
