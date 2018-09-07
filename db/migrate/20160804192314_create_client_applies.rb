class CreateClientApplies < ActiveRecord::Migration
  def change
    create_table :client_applies do |t|
      t.string :first_name
      t.string :last_name
      t.date :dob
      t.string :phone
      t.string :email
      t.string :ssn
      t.string :building
      t.string :unit
      t.string :current_addr
      t.string :current_landlord
      t.string :current_landlord_ph
      t.integer :current_rent
      t.string :prev_addr
      t.string :prev_landlord
      t.string :prev_landlord_ph
      t.integer :prev_rent
      t.string :position
      t.string :company
      t.date :start_date
      t.integer :salary
      t.string :pet
      t.string :breed
      t.string :pet_name
      t.integer :pet_age
      t.float :pet_weight
      t.string :emergency_name
      t.string :emergency_addr
      t.string :emergency_phone
      t.string :emergency_relation
      t.string :referral
      t.boolean :is_employed
      t.integer :status

      t.timestamps
    end
  end
end
