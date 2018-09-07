
class CreateMtaInfoLines < ActiveRecord::Migration
  def change
    create_table :mta_info_lines do |t|
      t.string :location
      t.string :name
      t.string :long_name
      t.string :icon_url
      t.string :mta_info_type,limit: 10

      t.timestamps
    end
  end
end
