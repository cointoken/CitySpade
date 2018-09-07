class RenameColumnsPoliticalToSearchRecords < ActiveRecord::Migration
  def change
    rename_column :search_records, :search_name, :title
    rename_column :search_records, :political, :current_area
  end
end
