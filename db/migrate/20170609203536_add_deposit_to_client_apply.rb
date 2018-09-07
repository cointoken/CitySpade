class AddDepositToClientApply < ActiveRecord::Migration
  def change
    add_column :client_applies, :deposit, :float, default: 0.00
  end
end
