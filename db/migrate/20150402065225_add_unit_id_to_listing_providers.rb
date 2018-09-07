class AddUnitIdToListingProviders < ActiveRecord::Migration
  def change
    add_column :listing_providers, :unit_id, :integer
  end
end
