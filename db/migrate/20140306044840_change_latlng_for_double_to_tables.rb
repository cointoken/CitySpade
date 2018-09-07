class ChangeLatlngForDoubleToTables < ActiveRecord::Migration
  def change
    tables = [:listings, :listing_places, :transport_places]
    cols   = [:lat, :lng]
    tables.each do |tb|
      cols.each do |col|
        change_column tb, col, :double
      end
    end
  end
end
