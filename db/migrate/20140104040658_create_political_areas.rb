class CreatePoliticalAreas < ActiveRecord::Migration
  def change
    create_table :political_areas do |t|
      t.string :long_name
      t.string :short_name
      t.string :target
      t.integer :parent_id

      t.timestamps
    end
  end
end
