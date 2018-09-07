class AddIndexToAddress < ActiveRecord::Migration
  def change
    add_index :buildings, :formatted_address, unique: true
    remove_column :buildings, :apt_amenities, :text
    remove_column :buildings, :neighborhood, :text
  end
end
