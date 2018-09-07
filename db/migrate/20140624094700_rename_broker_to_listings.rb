class RenameBrokerToListings < ActiveRecord::Migration
  def change
    rename_column :listings, :broker, :broker_name
  end
end
