class AddTokenToAccountOmniauths < ActiveRecord::Migration
  def change
    add_column :account_omniauths, :token, :string
    add_column :account_omniauths, :expires_at, :datetime
  end
end
