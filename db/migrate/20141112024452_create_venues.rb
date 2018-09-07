class CreateVenues < ActiveRecord::Migration
  def change
    create_table :venues do |t|
      t.references :political_area, index: true
      t.string :region_type
      t.integer :region_id
      t.float :building
      t.float :management
      t.float :convenience
      t.float :things_to_do
      t.float :safety
      t.float :ground
      t.float :quietness
      t.float :lat
      t.float :lng
      t.string :formatted_address
      t.string :permalink, index: true
      t.timestamps
    end
  end
end
