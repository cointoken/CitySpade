class CreateTransportDistances < ActiveRecord::Migration
  def change
    create_table :transport_distances do |t|
      t.references :listing, index: true
      t.references :transport_place, index: true
      t.integer :duration
      t.integer :distance

      t.timestamps
    end
  end
end
