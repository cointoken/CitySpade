class CreateReviewApartments < ActiveRecord::Migration
  def change
    create_table :review_apartments do |t|
      t.references :review, index: true
      t.integer :beds
      t.integer :baths
      t.float :price
      t.text :comment

    end
  end
end
