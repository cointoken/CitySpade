class AddTimestampRoommates < ActiveRecord::Migration
  def change
    add_timestamps(:roommates)
  end
end
