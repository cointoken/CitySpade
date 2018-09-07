class ChangeLatlngColumnToMtaInfoSts < ActiveRecord::Migration
  def change
    change_column :mta_info_sts, :lat, :double, index: true
    change_column :mta_info_sts, :lng, :double, index: true
  end
end
