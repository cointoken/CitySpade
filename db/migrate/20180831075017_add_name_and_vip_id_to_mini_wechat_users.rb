class AddNameAndVipIdToMiniWechatUsers < ActiveRecord::Migration
  def change
    add_column :mini_wechat_users, :name, :string
    add_column :mini_wechat_users, :vip_id, :string, unique: true
    add_index :mini_wechat_users, :vip_id
  end
end
