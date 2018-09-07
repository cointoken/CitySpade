class AddTypeToSearchRecords < ActiveRecord::Migration
  def change
    add_column :search_records, :type, :string
  end
end
