class AddOverallQualityToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :overall_quality, :float
    reversible do |dir|
      dir.up { Venue.all.each{|s| s.set_ratings_hook true }}
    end
  end
end
