class CreateSpadePasses < ActiveRecord::Migration
  def change
    create_table :spade_passes do |t|
      t.string :title
      t.string :city
      t.string :borough
      t.string :spade_pass_type
      t.integer :account_id, null: false, index: true
      t.references :political_area, index: true
      t.string :contact_tel
      t.string :formatted_address
      t.string :street_address
      t.string :zipcode
      t.text :description
      t.string :special_offers
      t.float :lat
      t.float :lng

      t.timestamps
    end
  end
end
