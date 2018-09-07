class AddResidencyToClientApply < ActiveRecord::Migration
  def change
    add_column :client_applies, :residency, :string
    add_column :client_applies, :access_token, :string
    add_index :client_applies, :access_token, unique: true
  end
end
