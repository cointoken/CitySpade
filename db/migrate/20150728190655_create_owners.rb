class CreateOwners < ActiveRecord::Migration
  def change
    create_table :owners do |t|
      t.string :name, null: false
      t.string :street_address
      t.string :city
      t.string :zipcode
      t.string :email, null: false
      t.string :phone


      t.timestamps
    end
  end
end
