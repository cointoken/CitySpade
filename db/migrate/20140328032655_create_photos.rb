class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :imageable_type
      t.integer :imageable_id
      t.string :image

      t.timestamps
    end
  end
end
