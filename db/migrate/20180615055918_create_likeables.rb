class CreateLikeables < ActiveRecord::Migration
  def change
    create_table :likeables do |t|
      t.integer :account_id
      t.integer :collection_id
      t.string  :collection_type
      t.integer :like, default: 1
      t.timestamps

      t.index ["collection_type", "collection_id", "like"], name: "index_likeable_on_collection_type_and_collection_id_and_like"
    end
  end
end
