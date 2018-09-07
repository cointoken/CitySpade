class AddPermalinkToPoliticalAreas < ActiveRecord::Migration
  def change
    add_column :political_areas, :permalink, :string, limit: 60
  end
end
