class AddParentIdToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :parent_id, :integer, index: true
  end
end
