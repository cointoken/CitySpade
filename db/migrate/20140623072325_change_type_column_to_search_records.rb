class ChangeTypeColumnToSearchRecords < ActiveRecord::Migration
  def change
    if SearchRecord.column_names.include? 'type'
      rename_column :search_records, :type, :flag
    end
  end
end
