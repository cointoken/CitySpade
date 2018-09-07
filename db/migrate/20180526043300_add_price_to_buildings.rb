class AddPriceToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :price, :float
  end
end
