class AddMlsColumnsToListings < ActiveRecord::Migration
  def change
    add_column :listings, :street_address, :string
    add_column :listings, :mls_id, :integer
    add_column :listings, :date_listed, :date
  end
end
