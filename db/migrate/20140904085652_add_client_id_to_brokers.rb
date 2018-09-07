class AddClientIdToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :client_id, :string, limit: 30
  end
end
