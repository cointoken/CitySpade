class RemoveAddFieldsToAgents < ActiveRecord::Migration
  def change
    remove_column :accounts, :prefered_name, :string
    remove_column :accounts, :title, :string
    remove_column :accounts, :wechat, :string
    remove_column :accounts, :languages, :string
    remove_column :accounts, :about_me, :text
    remove_column :accounts, :experience, :text
    remove_column :agents, :website, :string
    remove_column :agents, :office_tel, :string
    remove_column :agents, :fax_tel, :string
    remove_column :agents, :mobile_tel, :string
    add_column :agents, :wechat, :string
    remove_column :agents, :sizes, :string
    remove_column :agents, :origin_url, :string
  end
end
