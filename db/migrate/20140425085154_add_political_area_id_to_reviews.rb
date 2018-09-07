class AddPoliticalAreaIdToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :political_area_id, :integer, index: true
    add_column :reviews, :full_address, :string
    add_column :reviews, :lat, :float
    add_column :reviews, :lng, :float
    Review.init_improve_address
  end
end
