class AddAccountIdToClientApplies < ActiveRecord::Migration
  def change
    add_column :client_applies, :account_id, :integer
  end
end
