class AddFlagToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :flag, :integer, limit: 1, default: 0
  end
end
