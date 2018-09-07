class CreateSearchForMes < ActiveRecord::Migration
  def change
    create_table :search_for_mes do |t|
      t.string :name
      t.string :boroughs
      t.integer :beds
      t.float :baths
      t.integer :budget
      t.date :move_in_date
      t.boolean :is_employed
      t.string :transportation
      t.string :email

      t.timestamps
    end
  end
end
