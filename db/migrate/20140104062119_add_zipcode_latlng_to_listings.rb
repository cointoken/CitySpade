class AddZipcodeLatlngToListings < ActiveRecord::Migration
  def change
    add_column :listings, :zipcode, :string
    add_column :listings, :lat, :float
    add_column :listings, :lng, :float
  end
end
