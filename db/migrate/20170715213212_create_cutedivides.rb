class CreateCutedivides < ActiveRecord::Migration
  def change
    create_table :cutedivides do |t|
      t.string :name
      t.date :dob
      t.string :phone
      t.string :wechat
      t.boolean :paid

      t.timestamps
    end
  end
end
