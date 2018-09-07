class AddStatusToRooms < ActiveRecord::Migration
  def change
    add_column :rooms, :status, :integer, default: 0
  end
end
