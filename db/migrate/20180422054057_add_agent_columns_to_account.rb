class AddAgentColumnsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :prefered_name, :string
    add_column :accounts, :title, :string
    add_column :accounts, :wechat, :string
    add_column :accounts, :languages, :string
    add_column :accounts, :about_me, :text
    add_column :accounts, :experience, :text
  end
end
