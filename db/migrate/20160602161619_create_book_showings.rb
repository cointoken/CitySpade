class CreateBookShowings < ActiveRecord::Migration
  def change
    create_table :book_showings do |t|
      t.references :date, references: :showing_dates, index: true, foreign_key: true
      t.references :slot, references: :showing_time_slots, index: true, foreign_key: true
      t.references :client, references: :client_checkins, index: true, foreign_key: true
      t.timestamps null: false
    end

    create_table :showing_dates do |t|
      t.date :date, null: false
    end

    create_table :showing_time_slots do |t|
      t.string :start_time, null: false
      t.string :end_time, null: false
    end

  end
end
