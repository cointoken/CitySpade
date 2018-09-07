class ChangeColumnsToAgents < ActiveRecord::Migration
  def change
    rename_column :agents, :avatar_url, :origin_url
    add_column :agents, :s3_url, :string
    add_column :agents, :sizes, :string
  end
end
