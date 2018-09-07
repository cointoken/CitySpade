class RemoveColumnsFromListings < ActiveRecord::Migration
  def change
    remove_column :listings, :room_type, :string#, :available_begin_at, :available_end_at
    remove_column :listings, :available_begin_at, :date#, :available_begin_at, :available_end_at
    remove_column :listings, :available_end_at, :date#, :available_begin_at, :available_end_at
  end
end
