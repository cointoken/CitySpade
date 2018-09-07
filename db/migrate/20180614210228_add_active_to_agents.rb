class AddActiveToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :active, :boolean, default: false
  end
end
