class CreateTransportPlaces < ActiveRecord::Migration
  def change
    create_table :transport_places do |t|
      t.string :name
      t.string :place_type
      t.float :lat
      t.float :lng
      t.references :political_area, index: true

      t.timestamps
    end
  end
end
