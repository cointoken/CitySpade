class ChangeStatusSearchForMe < ActiveRecord::Migration
  def change
    change_column :client_applies, :status, :string
  end
end
