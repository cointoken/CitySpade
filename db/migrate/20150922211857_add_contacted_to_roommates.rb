class AddContactedToRoommates < ActiveRecord::Migration
  def change
    add_column :roommates, :contacted, :integer, default: 0
  end
end
