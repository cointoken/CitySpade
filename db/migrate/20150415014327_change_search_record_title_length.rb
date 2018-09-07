class ChangeSearchRecordTitleLength < ActiveRecord::Migration
  def change
    change_column :search_records, :title, :string, limit: 150
  end
end
