class CreateMlsInfos < ActiveRecord::Migration
  def change
    create_table :mls_infos do |t|
      t.references :listing, index: true
      t.references :broker, index: true
      t.integer :mls_id

      t.timestamps
    end
  end
end
