class AddTargetToListingMtaLines < ActiveRecord::Migration
  def change
    add_column :listing_mta_lines, :target, :string, limit: 20
  end
end
