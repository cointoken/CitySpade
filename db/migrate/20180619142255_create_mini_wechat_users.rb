class CreateMiniWechatUsers < ActiveRecord::Migration
  def change
    create_table :mini_wechat_users do |t|
      t.string :nickname
      t.string :phone
      t.string :open_id

      t.timestamps
    end
  end
end
