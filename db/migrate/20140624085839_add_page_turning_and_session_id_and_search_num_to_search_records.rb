class AddPageTurningAndSessionIdAndSearchNumToSearchRecords < ActiveRecord::Migration
  def change
    add_column :search_records, :page_turning, :boolean, :default => false
    add_column :search_records, :session_id, :string, limit: 50
    add_column :search_records, :re_search_num, :integer, :default => 1
  end
end
