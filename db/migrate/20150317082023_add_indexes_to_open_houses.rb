class AddIndexesToOpenHouses < ActiveRecord::Migration
  def change
    add_index :open_houses, :open_date
    add_index :open_houses, :listing_id
  end
end
