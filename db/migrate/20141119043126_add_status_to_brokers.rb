class AddStatusToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :status, :integer, default: 0, limit: 1
  end
end
