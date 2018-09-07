class AddIsRecommendedToSpadePasses < ActiveRecord::Migration
  def change
    add_column :spade_passes, :is_recommended, :bool, default: false
  end
end
