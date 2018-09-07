class AddOnlyVenueFlagToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :only_venue_flag, :boolean, default: false
  end
end
