class RemovefieldsfromListings < ActiveRecord::Migration
  def change
    remove_column :listings, :free_month, :boolean
    remove_column :listings, :promotion, :boolean
    remove_column :listings, :deal_expires, :date
  end
end
