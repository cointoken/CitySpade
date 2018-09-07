class AddOfficeAddressToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :office_address, :string
  end
end
