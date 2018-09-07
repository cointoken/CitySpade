class RenameAccountIdToLikeables < ActiveRecord::Migration
  def change
    rename_column :likeables, :account_id, :mini_wechat_user_id
  end
end
