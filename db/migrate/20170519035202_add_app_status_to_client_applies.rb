class AddAppStatusToClientApplies < ActiveRecord::Migration
  def change
    add_column :client_applies, :app_status, :integer, default: 0
  end
end
