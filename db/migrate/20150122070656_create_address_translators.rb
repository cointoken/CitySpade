class CreateAddressTranslators < ActiveRecord::Migration
  def change
    create_table :address_translators do |t|
      t.integer :low_num
      t.integer :hight_num
      t.string :street_name, limit: 100, index: true
      t.integer :nyc_bin
      t.string :borough, limit: 30
      t.string :city, limit: 20
      t.string :zipcode, limit: 6, index: true
      t.references :building, index: true
      t.integer :master_id, index: true
      t.timestamps
    end
  end
end
