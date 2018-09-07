class AddLeaseEndToReviewApartments < ActiveRecord::Migration
  def change
    add_column :review_apartments, :lease_end, :date
    rename_column :reviews, :build_name, :building_name
  end
end
