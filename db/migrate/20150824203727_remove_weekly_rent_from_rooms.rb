class RemoveWeeklyRentFromRooms < ActiveRecord::Migration
  def change
    remove_column :rooms, :price_week
  end
end
