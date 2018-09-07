class AddLatlngToMtaInfoSts < ActiveRecord::Migration
  def change
    add_column :mta_info_sts, :lat, :float
    add_column :mta_info_sts, :lng, :float
  end
end
