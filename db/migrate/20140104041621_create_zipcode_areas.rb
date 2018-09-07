class CreateZipcodeAreas < ActiveRecord::Migration
  def change
    create_table :zipcode_areas do |t|
      t.string :zipcode
      t.references :political_area, index: true

      t.timestamps
    end
  end
end
