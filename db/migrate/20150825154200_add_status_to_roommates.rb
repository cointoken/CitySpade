class AddStatusToRoommates < ActiveRecord::Migration
  def change
    add_column :roommates, :status, :integer, default: 0
  end
end
