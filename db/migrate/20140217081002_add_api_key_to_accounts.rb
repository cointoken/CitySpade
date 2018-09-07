class AddApiKeyToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :api_key, :string
    add_index :accounts, :api_key
  end
end
