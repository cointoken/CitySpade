class AddWechatNumAndEmailToMiniWechatUsers < ActiveRecord::Migration
  def change
    add_column :mini_wechat_users, :wechat_num, :string
    add_column :mini_wechat_users, :email, :string
  end
end
