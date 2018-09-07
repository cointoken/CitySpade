class AddDeactivateToListings < ActiveRecord::Migration
  def change
    add_column :listings, :deactivate, :boolean, default: false
  end
end
