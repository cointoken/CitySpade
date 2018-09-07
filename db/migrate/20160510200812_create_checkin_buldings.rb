class CreateCheckinBuldings < ActiveRecord::Migration
  def change
    create_table :checkin_buildings do |t|
      t.string :name, null:false
      t.references :client, references: :client_checkins, index: true, foreign_key: true
      
      t.timestamps null: false
    end
  end
end
