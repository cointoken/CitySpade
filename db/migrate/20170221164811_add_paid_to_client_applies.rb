class AddPaidToClientApplies < ActiveRecord::Migration
  def change
    add_column :client_applies, :paid, :boolean, default: false
  end
end
