class AddBuildingToCutedivide < ActiveRecord::Migration
  def change
    add_column :cutedivides, :building, :string
    add_column :cutedivides, :unit, :string
  end
end
