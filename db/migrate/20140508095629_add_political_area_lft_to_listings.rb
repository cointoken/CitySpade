class AddPoliticalAreaLftToListings < ActiveRecord::Migration
  def change
    add_column :listings, :political_area_lft, :integer, index: true
    #Listing.all.each do |listing|
      #listing.political_area_lft = listing.political_area.lft if listing.political_area
      #listing.save
    #end
  end
end
