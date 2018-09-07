class AddPricesToRooms < ActiveRecord::Migration
  def change
    add_column :rooms, :price_month, :integer
    add_column :rooms, :price_week, :integer
  end
end
