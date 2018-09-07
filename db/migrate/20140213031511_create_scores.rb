class CreateScores < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? 'transport_scores'
      drop_table :transport_scores
    end
    create_table :scores do |t|
      t.float :transport
      t.float :price
      t.references :listing

      t.timestamps
    end
  end
end
