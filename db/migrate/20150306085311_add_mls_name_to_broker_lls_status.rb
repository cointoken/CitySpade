class AddMlsNameToBrokerLlsStatus < ActiveRecord::Migration
  def change
    add_column :broker_lls_statuses, :mls_name, :string, limit: 30, index: true
    add_index :broker_lls_statuses, :status_date
    add_index :broker_lls_statuses, :name
  end
end
