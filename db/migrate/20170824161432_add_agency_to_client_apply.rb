class AddAgencyToClientApply < ActiveRecord::Migration
  def change
    add_column :client_applies, :agency, :string, default: nil
  end
end
