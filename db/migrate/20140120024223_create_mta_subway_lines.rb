class CreateMtaSubwayLines < ActiveRecord::Migration
  def change
    create_table :mta_subway_lines do |t|
      t.string :location
      t.string :name
      t.string :line_name
      t.string :icon_url

      t.timestamps
    end
  end
end
