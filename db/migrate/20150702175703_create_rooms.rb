class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.integer :account_id, index: true
      t.string :room_type
      t.string :title, null: false
      t.string :street_address
      t.string :city
      t.string :zipcode
      t.integer :price
      t.integer :bedrooms
      t.integer :bathrooms
      t.date :available_begin_at
      t.date :available_end_at
      t.string :state

      t.timestamps
    end
  end
end
