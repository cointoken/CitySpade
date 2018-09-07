class AddAddTypeToClientCheckins < ActiveRecord::Migration
  def change
    add_column :client_checkins, :add_type, :boolean, default: false
  end
end
