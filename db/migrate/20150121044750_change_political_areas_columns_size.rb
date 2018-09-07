class ChangePoliticalAreasColumnsSize < ActiveRecord::Migration
  def change
    change_column :political_areas, :second_name, :string, limit: 30
    change_column :political_areas, :long_name, :string, limit: 60
    change_column :political_areas, :short_name, :string, limit: 60
    change_column :political_areas, :target, :string, limit: 30
  end
end
