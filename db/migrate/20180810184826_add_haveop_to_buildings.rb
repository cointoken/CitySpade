class AddHaveopToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :haveop, :boolean, default: false
  end
end
