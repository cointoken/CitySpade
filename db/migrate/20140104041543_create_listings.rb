class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.string :title
      t.references :political_area, index: true
      t.string :unit
      t.integer :beds
      t.float :baths
      t.float :sq_ft
      t.string :type_name
      t.string :contact_name
      t.string :contact_tel

      t.timestamps
    end
  end
end
