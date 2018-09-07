class AddRankToSpadePasses < ActiveRecord::Migration
  def change
    add_column :spade_passes, :rank, :integer
  end
end
