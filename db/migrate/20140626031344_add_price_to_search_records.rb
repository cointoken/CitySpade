class AddPriceToSearchRecords < ActiveRecord::Migration
  def change
    add_column :search_records, :min_price, :integer
    add_column :search_records, :max_price, :integer
  end
end
