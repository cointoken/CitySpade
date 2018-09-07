class AddAccountIdToAgents < ActiveRecord::Migration
  def change
    add_reference :agents, :account, index: true
  end
end
