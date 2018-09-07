class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.string :address
      t.string :build_name
      t.string :city
      t.string :state
      t.integer :review_type

      t.timestamps
    end
  end
end
