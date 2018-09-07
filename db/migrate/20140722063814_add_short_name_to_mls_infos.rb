class AddShortNameToMlsInfos < ActiveRecord::Migration
  def change
    add_column :mls_infos, :broker_name, :string, limit: 50
    add_column :mls_infos, :name, :string, limit: 50
  end
end
