class CreateMtaInfoSts < ActiveRecord::Migration
  def change
    create_table :mta_info_sts do |t|
      t.string :name
      t.string :long_name
      t.references :mta_info_line, index: true

      t.timestamps
    end
  end
end
