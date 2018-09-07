class AddColumnsToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :email, :string
    add_column :agents, :avatar_url, :string
  end
end
