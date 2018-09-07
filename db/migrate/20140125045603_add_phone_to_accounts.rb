class AddPhoneToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :first_phone, :string, limit: 20
    add_column :accounts, :last_phone, :string, limit: 20
  end
end
