class CreateAccountInboxes < ActiveRecord::Migration
  def change
    create_table :account_inboxes do |t|
      t.references :account, index: true
      t.references :inbox, index: true
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
