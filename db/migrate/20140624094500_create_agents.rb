class CreateAgents < ActiveRecord::Migration
  def change
    create_table :agents do |t|
      t.references :broker, index: true
      t.string :name
      t.string :tel

      t.timestamps
    end
  end
end
