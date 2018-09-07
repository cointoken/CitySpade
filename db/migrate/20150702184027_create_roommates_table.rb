class CreateRoommatesTable < ActiveRecord::Migration
  def change
    create_table :roommates do |t|
      t.integer :account_id, null: false, index: true
      t.string :gender
      t.integer :budget
      t.string :pets_allowed
      t.text :about_me
      t.boolean :students_only
      t.string :raw_neighborhood
      t.string :borough
      t.string :title, null: false
    end
  end
end
