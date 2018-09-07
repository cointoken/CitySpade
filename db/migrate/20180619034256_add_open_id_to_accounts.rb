class AddOpenIdToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :open_id, :string
  end
end
