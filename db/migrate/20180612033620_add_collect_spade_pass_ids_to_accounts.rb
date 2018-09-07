class AddCollectSpadePassIdsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :collect_spade_pass_ids, :string
  end
end
