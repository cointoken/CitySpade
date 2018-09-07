class CreateAccountOmniauths < ActiveRecord::Migration
  def change

    remove_column :accounts, :provider
    remove_column :accounts, :uid

    create_table :account_omniauths do |t|
      t.references :account, index: true
      t.string :provider
      t.string :uid

      t.timestamps
    end
  end
end
