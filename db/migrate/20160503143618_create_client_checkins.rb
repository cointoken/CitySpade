class CreateClientCheckins < ActiveRecord::Migration
  def change
    create_table :client_checkins do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone, null: false, limit: 20

      t.timestamps null: false
    end

    create_table :client_roommates do |t|
      t.string :first_name
      t.string :last_name
      t.references :client, references: :client_checkins, index: true, foreign_key: true
      
      t.timestamps null: false
    end
  end
end
