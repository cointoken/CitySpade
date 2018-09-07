class AddLocationInfoToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :street_address, :string, limit: 100
    add_column :brokers, :state, :string, limit: 10
    add_column :brokers, :zipcode, :string, limit: 20
    add_column :brokers, :website, :string, limit: 50
  end
end
