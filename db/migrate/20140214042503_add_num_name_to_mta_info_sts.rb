class AddNumNameToMtaInfoSts < ActiveRecord::Migration
  def change
    add_column :mta_info_sts, :num_name, :string
  end
end
