class AddCollectBuildingIdsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :collect_building_ids, :string
  end
end
