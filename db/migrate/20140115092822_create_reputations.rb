class CreateReputations < ActiveRecord::Migration
  def up
    create_table :reputations do |t|
      t.integer :account_id
      t.string :reputable_type
      t.integer :reputable_id
      t.string :category

      t.timestamps
    end
  end

  def down
    drop_table :reputations
  end
end
