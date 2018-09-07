class CreateRoomDetails < ActiveRecord::Migration
  def change
    create_table :room_details do |t|
      t.integer :room_id, null: false, index: true
      t.string :amenities
      t.text :description
      t.string :pets_allowed

      t.timestamps
    end
  end
end
