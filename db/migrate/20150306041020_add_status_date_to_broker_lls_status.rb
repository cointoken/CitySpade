class AddStatusDateToBrokerLlsStatus < ActiveRecord::Migration
  def change
    add_column :broker_lls_statuses, :status_date, :date
  end
end
