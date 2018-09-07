class ChangeMlsIdToListings < ActiveRecord::Migration
  def change
    rename_column :listings, :mls_id, :mls_info_id
  end
end
