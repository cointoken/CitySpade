class CreateListingSubwayLines < ActiveRecord::Migration
  def change
    create_table :listing_subway_lines do |t|
      t.references :listing, index: true
      t.references :mta_subway_line, index: true

      t.timestamps
    end
  end
end
