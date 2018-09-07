class AddBrokerToListings < ActiveRecord::Migration
  def change
    add_column :listings, :broker, :string
  end
end
