class RemovePriceToBuildings < ActiveRecord::Migration
  def change
    remove_column :buildings, :price
  end
end
