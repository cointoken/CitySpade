class CreateBrokerLlsStatuses < ActiveRecord::Migration
  def change
    create_table :broker_lls_statuses do |t|
      t.string :name
      t.string :active_lls
      t.string :added_today
      t.string :expired_today
      t.string :manhattan
      t.string :brooklyn
      t.string :queens
      t.string :bronx
      t.string :other_cities
      t.string :active_no_fee
      t.string :added_no_fee
      t.string :expired_no_fee

      t.timestamps
    end
  end
end
