class AddMaintenanceToListingDetails < ActiveRecord::Migration
  def change
    add_column :listing_details, :maintenance, :integer, default: 0
  end
end
