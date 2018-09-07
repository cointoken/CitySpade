class CreateOpenHouses < ActiveRecord::Migration
  def change
    create_table :open_houses do |t|
      t.date :open_date, index: true
      t.time :begin_time
      t.time :end_time
      t.integer :listing_id, index: true

      t.timestamps
    end
  end
end
