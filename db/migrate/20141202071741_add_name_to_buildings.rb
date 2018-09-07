class AddNameToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :name, :string, limit: 40
  end
end
