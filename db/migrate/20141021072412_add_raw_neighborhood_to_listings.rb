class AddRawNeighborhoodToListings < ActiveRecord::Migration
  def change
    add_column :listings, :raw_neighborhood, :string, limit:  50
  end
end
