class AddRentalDealsToListings < ActiveRecord::Migration
  def up
     add_column :listings, :free_month, :boolean, default: false
     add_column :listings, :promotion, :boolean, default: false
     add_column :listings, :deal_expires, :date
  end

  def down
    remove_column :listings, :free_month, :boolean 
    remove_column :listings, :promotion, :boolean
    remove_column :listings, :deal_expires, :date
  end
end
