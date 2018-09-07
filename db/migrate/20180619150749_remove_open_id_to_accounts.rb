class RemoveOpenIdToAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :open_id, :string
  end
end
