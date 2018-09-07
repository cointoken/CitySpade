class AddBoroughToMtaInfoSts < ActiveRecord::Migration
  def change
    add_column :mta_info_sts, :borough, :string, limit: 50
  end
end
