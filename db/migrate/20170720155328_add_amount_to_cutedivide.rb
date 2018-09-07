class AddAmountToCutedivide < ActiveRecord::Migration
  def change
    add_column :cutedivides, :amount, :float, default: 0.00
  end
end
