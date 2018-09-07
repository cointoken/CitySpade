class AddColumnRoommates < ActiveRecord::Migration
  def change
    add_column :roommates, :num_roommates, :integer
    add_column :roommates, :location, :string
  end
end
