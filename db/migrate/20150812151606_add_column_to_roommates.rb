class AddColumnToRoommates < ActiveRecord::Migration
  def change
    add_column :roommates, :move_in_date, :date
    add_column :roommates, :duration, :integer
  end
end
