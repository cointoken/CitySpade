class AddExpiredDateToListings < ActiveRecord::Migration
  def change
    add_column :listings, :expired_date, :datetime
    add_column :listings, :is_fee, :boolean
  end
end
