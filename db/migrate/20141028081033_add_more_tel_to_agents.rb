class AddMoreTelToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :office_tel, :string, limit: 20
    add_column :agents, :fax_tel, :string, limit: 20
    add_column :agents, :mobile_tel, :string, limit: 20
    add_column :agents, :address, :string
  end
end
