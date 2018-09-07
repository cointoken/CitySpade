class AddRoomTypeAndAvailableDateToListings < ActiveRecord::Migration
  def change
    add_column :listings, :room_type, :string
    add_column :listings, :available_begin_at, :date
    add_column :listings, :available_end_at, :date
  end
end
