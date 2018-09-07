class AddAvailableRoomsToRoom < ActiveRecord::Migration
  def up
    add_column :rooms, :rooms_available, :integer, default: 1
  end

  def down
    remove_column :rooms, :rooms_available
  end
end
