class AddTransactionIdToCutedivide < ActiveRecord::Migration
  def change
    add_column :cutedivides, :email, :string
    add_column :cutedivides, :transact_id, :string
    add_column :client_applies, :transact_id, :string
    add_column :client_applies, :dep_transact_id, :string
    remove_column :cutedivides, :paid, :boolean
    remove_column :cutedivides, :dob, :string
  end
end
