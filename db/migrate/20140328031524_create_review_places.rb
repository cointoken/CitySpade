class CreateReviewPlaces < ActiveRecord::Migration
  def change
    create_table :review_places do |t|
      t.references :review, index: true
      t.string :place_type
      t.string :name
      t.text :comment

    end
  end
end
