class AddBflagToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :bflag, :boolean, default: false, null: false
  end
end
