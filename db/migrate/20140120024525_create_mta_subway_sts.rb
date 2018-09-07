class CreateMtaSubwaySts < ActiveRecord::Migration
  def change
    create_table :mta_subway_sts do |t|
      t.references :mta_subway_line, index: true
      t.string :name
      t.string :long_name
      t.string :num_name
      t.string :location

      t.timestamps
    end
  end
end
