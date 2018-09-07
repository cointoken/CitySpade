class AddIndexToBroker < ActiveRecord::Migration
  def change
    add_index :brokers, :name
  end
end
