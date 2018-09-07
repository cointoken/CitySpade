class CreateBuildingImages < ActiveRecord::Migration
  def change
    create_table :building_images do |t|
      t.string :image
      t.references :building, references: :buildings, index: true, foreign_key: true
      t.timestamps null: false
    end

    create_table :floorplans do |t|
      t.string :image
      t.integer :beds
      t.float :baths
      t.integer :price
      t.integer :sqft
      t.references :building, references: :buildings, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
