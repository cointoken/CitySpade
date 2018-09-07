class AddColumnsRoomsTable < ActiveRecord::Migration
  def change
    add_column :rooms, :political_area_id, :integer
    add_column :rooms, :lat, :float
    add_column :rooms, :lng, :float
    add_column :rooms, :formatted_address, :string
  end
end
