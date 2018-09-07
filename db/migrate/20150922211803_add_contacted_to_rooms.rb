class AddContactedToRooms < ActiveRecord::Migration
  def change
    add_column :rooms, :contacted, :integer, default: 0
  end
end
