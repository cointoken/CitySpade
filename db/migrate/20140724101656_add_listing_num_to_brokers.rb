class AddListingNumToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :listing_num, :integer
  end
end
