class ChangeAccountInboxColumnName < ActiveRecord::Migration
  def change
    rename_column :account_inboxes, :read, :is_read
  end
end
