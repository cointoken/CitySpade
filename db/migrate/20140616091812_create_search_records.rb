class CreateSearchRecords < ActiveRecord::Migration
  def change
    create_table :search_records do |t|
      t.string :search_name, limit: 30
      t.string :political, limit: 40
      t.string :beds
      t.string :baths
      t.integer :political_results_count
      t.integer :results_count
      t.integer :account_id

      t.timestamps
    end
    add_index :search_records, :search_name
  end
end
