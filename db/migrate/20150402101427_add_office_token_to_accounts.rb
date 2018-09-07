class AddOfficeTokenToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :office_token, :string
  end
end
