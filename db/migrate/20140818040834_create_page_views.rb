class CreatePageViews < ActiveRecord::Migration
  def change
    create_table :page_views do |t|
      t.string :page_type
      t.integer :page_id
      t.integer :num, default: 0
      t.timestamps
    end
  end
end
