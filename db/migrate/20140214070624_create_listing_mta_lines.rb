class CreateListingMtaLines < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? 'listing_subway_lines'
      Listing.all.each do |listing|
        listing.cancel_old_listing_places
      end
      drop_table :listing_subway_lines
      drop_table :mta_subway_lines
      drop_table :mta_subway_sts
    end
    create_table :listing_mta_lines do |t|
      t.references :listing, index: true
      t.references :mta_info_line, index: true
      t.references :listing_place, index: true
      t.string :mta_info_type, limit: 10
      t.float :distance
      t.float :duration

      t.timestamps
    end
  end
end
