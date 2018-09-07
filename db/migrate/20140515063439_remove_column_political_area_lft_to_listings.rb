class RemoveColumnPoliticalAreaLftToListings < ActiveRecord::Migration
  def change
    remove_column :listings, :political_area_lft
  end
end
