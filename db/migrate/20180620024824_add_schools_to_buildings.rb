class AddSchoolsToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :schools, :text
  end
end
