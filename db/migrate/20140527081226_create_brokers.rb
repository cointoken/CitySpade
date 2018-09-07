class CreateBrokers < ActiveRecord::Migration
  def change
    create_table :brokers do |t|
      t.string :name
      t.string :tel
      t.string :email

      t.timestamps
    end
  end
end
