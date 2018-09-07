class AddTargetToMtaInfoSt < ActiveRecord::Migration
  def change
    add_column :mta_info_sts, :target, :string, limit: 20
  end
end
