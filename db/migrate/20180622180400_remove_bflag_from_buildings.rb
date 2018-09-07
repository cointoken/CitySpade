class RemoveBflagFromBuildings < ActiveRecord::Migration
  def change
    remove_column :buildings, :bflag, :boolean
  end
end
