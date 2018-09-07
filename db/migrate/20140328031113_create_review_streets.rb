class CreateReviewStreets < ActiveRecord::Migration
  def change
    create_table :review_streets do |t|
      t.references :review, index: true
      t.integer :convenience
      t.integer :living
      t.integer :safety
      t.text :comment

    end
  end
end
