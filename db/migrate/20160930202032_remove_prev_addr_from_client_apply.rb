class RemovePrevAddrFromClientApply < ActiveRecord::Migration
  def change
    remove_column :client_applies, :prev_addr, :string
    remove_column :client_applies, :prev_landlord, :string
    remove_column :client_applies, :prev_landlord_ph, :string
    remove_column :client_applies, :prev_rent, :integer
  end
end
