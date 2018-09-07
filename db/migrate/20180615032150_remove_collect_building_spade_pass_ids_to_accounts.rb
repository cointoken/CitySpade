class RemoveCollectBuildingSpadePassIdsToAccounts < ActiveRecord::Migration
  def change
    remove_columns :accounts, :collect_building_ids
    remove_columns :accounts, :collect_spade_pass_ids
  end
end
