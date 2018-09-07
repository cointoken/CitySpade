class AddDiscountsExpiredDateToSpadePasses < ActiveRecord::Migration
  def change
    add_column :spade_passes, :discounts_expired_date, :datetime
  end
end
