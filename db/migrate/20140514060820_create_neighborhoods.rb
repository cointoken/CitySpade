class CreateNeighborhoods < ActiveRecord::Migration
  def change
    create_table :neighborhoods do |t|
      t.string :city, index: true
      t.string :borough
      t.string :name
      t.integer :hot, index: true, default: 0

      t.timestamps
    end
  end
end
