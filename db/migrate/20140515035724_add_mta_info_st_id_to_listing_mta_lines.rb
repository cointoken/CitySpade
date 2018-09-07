class AddMtaInfoStIdToListingMtaLines < ActiveRecord::Migration
  def change
    add_column :listing_mta_lines, :mta_info_st_id, :integer
  end
end
