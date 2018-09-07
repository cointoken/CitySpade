class AddExperienceToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :experience, :text
    rename_column :agents, :s3_url, :photo
  end
end
